#!/bin/bash
# Untangle with SmartCommit and Flexeme on one Defects4J (D4J) bug.
# - $1: D4J Project name
# - $2: D4J Bug Id
# - $3: Path where the results are stored.
# - $4: Path where the repo is checked out

# The decomposition results are written to ~/decomposition/smartcommit/<D4J bug>/ and ~/decomposition/<D4J bug>/flexeme/<D4J bug>/ subfolder.
# - flexeme/flexeme.dot: The PDG (untangling graph) generated by Flexeme
# - flexeme/time.csv: Run time allocated for untangling by Flexeme
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time allocated for untangling by SmartCommit

set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 4 ] ; then
    echo 'usage: decompose_bug.sh <project> <vid> <out_dir> <repository>'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

# Initialize exit code variable
export decompose_exit_code=0
# Make Flexeme deterministic
export PYTHONHASHSEED=0
# Initialize related directory for input and output
export evaluation_path="${out_dir}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground
# truth, decompositions in CSV format.
export decomposition_path="${out_dir}/decomposition"
export smartcommit_untangling_path="${out_dir}/decomposition/smartcommit"
export flexeme_untangling_path="${decomposition_path}/flexeme"

mkdir -p "$evaluation_path"
mkdir -p "$decomposition_path"
mkdir -p "$smartcommit_untangling_path"
mkdir -p "$flexeme_untangling_path"

echo ""
echo "Decompositing project $project, bug $vid, repository $repository"

# If D4J bug repository does not exist, checkout the D4J bug to repository and generates 6 artifacts for it.
if [ ! -d "${repository}" ] ; then
  mkdir -p "$repository"
  ./src/bash/main/generate_artifacts_bug.sh "$project" "$vid" "$repository"
fi

# Commit hash is the revision_fixed_ID
cd "$repository" || exit 1
commit="$(git rev-parse HEAD~1)"    # Clean fixed commit
export commit
cd - || exit 1
# Get source path and class path
sourcepath="$(defects4j export -p dir.src.classes -w "${repository}")"
sourcepath="${sourcepath}:$(defects4j export -p dir.src.tests -w "${repository}")"
classpath="$(defects4j export -p cp.compile -w "${repository}")"
classpath="${classpath}:$(defects4j export -p cp.test -w "${repository}")"

echo ""
smartcommit_untangling_results="${smartcommit_untangling_path}/${project}_${vid}/${commit}"

# Untangle with SmartCommit
if [ -d "$smartcommit_untangling_results" ]; then
  echo 'Untangling with SmartCommit ............................................. CACHED'
  regenerate_results=false
else
  echo 'Untangling with SmartCommit ...............................................'
  START_DECOMPOSITION="$(date +%s.%N)"
  "${JAVA11_HOME}/bin/java" -jar lib/smartcommitcore-1.0-all.jar -r "$repository" -c "$commit" -o "$smartcommit_untangling_path"
  END_DECOMPOSITION="$(date +%s.%N)"
  DIFF_DECOMPOSITION="$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)"
  echo "${project},${vid},smartcommit,${DIFF_DECOMPOSITION}" > "${smartcommit_untangling_results}/time.csv"
  echo 'Untangling with SmartCommit ............................................... OK'
  regenerate_results=true
fi

# Untangle with Flexeme

flexeme_untangling_results="${flexeme_untangling_path}/${project}_${vid}"
flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"

if [ -f "$flexeme_untangling_graph" ]; then
  echo 'Untangling with Flexeme ................................................. CACHED'
  regenerate_results=false
else
  echo 'Untangling with Flexeme ...............................................'
  mkdir -p "$flexeme_untangling_results"
  START_DECOMPOSITION="$(date +%s.%N)"
  if ./src/bash/main/untangle_flexeme.sh "$repository" "$commit" "$sourcepath" "$classpath" "${flexeme_untangling_graph}"
  then
    END_DECOMPOSITION="$(date +%s.%N)"
    DIFF_DECOMPOSITION="$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)"
    echo "${project},${vid},flexeme,${DIFF_DECOMPOSITION}" > "${flexeme_untangling_results}/time.csv"
    echo 'Untangling with Flexeme ................................................... OK'
    regenerate_results=true
  else
    echo 'Untangling with Flexeme ................................................. FAIL'
    regenerate_results=false
    decompose_exit_code=1
  fi
fi

# Retrieve untangling results from SmartCommit and parse them into a CSV file.
echo ""

smartcommit_result_out="${evaluation_path}/smartcommit.csv"
if [ -f "$smartcommit_result_out" ] && [ $regenerate_results = false ]; then
  echo 'Parsing SmartCommit results ............................................. CACHED'
else
  echo 'Parsing SmartCommit results ...............................................'
  if python3 src/python/main/parse_smartcommit_results.py "${smartcommit_untangling_path}/${project}_${vid}/${commit}" "$smartcommit_result_out"
  then
      echo 'Parsing SmartCommit results ............................................... OK'
  else
      echo -ne 'Parsing SmartCommit results ............................................. FAIL'
      decompose_exit_code=1
  fi
fi

# Retrieve untangling results from Flexeme and parse them into a CSV file.
echo ""

flexeme_result_out="${evaluation_path}/flexeme.csv"
if [ -f "$flexeme_result_out" ] && [ $regenerate_results == false ]; then
  echo -ne 'Parsing Flexeme results ................................................. CACHED\r'
else
  echo 'Parsing Flexeme results ...............................................'
  if python3 src/python/main/parse_flexeme_results.py "$flexeme_untangling_graph" "$flexeme_result_out"
  then
      echo 'Parsing Flexeme results ................................................... OK'
  else
      echo -ne 'Parsing Flexeme results ................................................. FAIL\r'
      decompose_exit_code=1
  fi
fi
echo ""
exit $decompose_exit_code
