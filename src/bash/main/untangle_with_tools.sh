#!/bin/bash
# Untangle with SmartCommit and Flexeme on one Defects4J (D4J) bug.
# Arguments:
# - $1: D4J Project name.
# - $2: D4J Bug Id.
# - $3: Directory where the results of the evaluation framework are stored.
# - $4: Directory where the repo is checked out.

# The untangling results are written to decomposition/smartcommit/<D4J bug>/ and ~/decomposition/flexeme/<D4J bug>/ subfolder.
# - flexeme/flexeme.dot: The PDG (untangling graph) generated by Flexeme
# - flexeme/time.csv: Run time allocated for untangling by Flexeme
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based untangling results
# - smartcommit/time.csv: Run time allocated for untangling by SmartCommit

set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 4 ] ; then
    echo 'usage: untangle_with_tools.sh <project> <vid> <out_dir> <repository>'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

# Initialize exit code variable
export untangle_exit_code=0
# Make Flexeme deterministic
export PYTHONHASHSEED=0
# Path containing the evaluation results. i.e., ground truth, untangling results in CSV format.
export evaluation_dir="${out_dir}/evaluation/${project}_${vid}"
export untangling_dir="${out_dir}/decomposition"
export smartcommit_untangling_dir="${out_dir}/decomposition/smartcommit"
export flexeme_untangling_dir="${untangling_dir}/flexeme"

mkdir -p "$evaluation_dir"
mkdir -p "$untangling_dir"
mkdir -p "$smartcommit_untangling_dir"
mkdir -p "$flexeme_untangling_dir"

echo ""
echo "Untangling project $project, bug $vid, repository $repository"

# If D4J bug repository does not exist, checkout the D4J bug to repository and
# generates 6 artifacts for it.
if [ ! -d "${repository}" ] ; then
  mkdir -p "$repository"
  ./src/bash/main/generate_d4j_artifacts.sh "$project" "$vid" "$repository"
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
smartcommit_untangling_results_dir="${smartcommit_untangling_dir}/${project}_${vid}/${commit}"

# Untangle with SmartCommit
if [ -d "$smartcommit_untangling_results_dir" ]; then
  echo 'Untangling with SmartCommit ............................................. CACHED'
  regenerate_results=false
else
  echo 'Untangling with SmartCommit ...............................................'
  START_UNTANGLING="$(date +%s.%N)"
  "${JAVA11_HOME}/bin/java" -jar lib/smartcommitcore-1.0-all.jar -r "$repository" -c "$commit" -o "$smartcommit_untangling_dir"
  END_UNTANGLING="$(date +%s.%N)"
  ELAPSED="$(echo "$END_UNTANGLING - $START_UNTANGLING" | bc)"
  echo "${project},${vid},smartcommit,${ELAPSED}" > "${smartcommit_untangling_results_dir}/time.csv"
  echo 'Untangling with SmartCommit ............................................... OK'
  regenerate_results=true
fi

# Untangle with Flexeme

flexeme_untangling_results="${flexeme_untangling_dir}/${project}_${vid}"
flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"

if [ -f "$flexeme_untangling_graph" ]; then
  echo 'Untangling with Flexeme ................................................. CACHED'
  regenerate_results=false
else
  echo 'Untangling with Flexeme ...............................................'
  mkdir -p "$flexeme_untangling_results"
  START_UNTANGLING="$(date +%s.%N)"
  if ./src/bash/main/untangle_flexeme.sh "$repository" "$commit" "$sourcepath" "$classpath" "${flexeme_untangling_graph}"
  then
    END_UNTANGLING="$(date +%s.%N)"
    ELAPSED="$(echo "$END_UNTANGLING - $START_UNTANGLING" | bc)"
    echo "${project},${vid},flexeme,${ELAPSED}" > "${flexeme_untangling_results}/time.csv"
    echo 'Untangling with Flexeme ................................................... OK'
    regenerate_results=true
  else
    echo 'Untangling with Flexeme ................................................. FAIL'
    regenerate_results=false
    untangle_exit_code=1
  fi
fi

# Retrieve untangling results from SmartCommit and parse them into a CSV file.
echo ""

smartcommit_result_out="${evaluation_dir}/smartcommit.csv"
if [ -f "$smartcommit_result_out" ] && [ $regenerate_results = false ]; then
  echo 'Parsing SmartCommit results ............................................. CACHED'
else
  echo 'Parsing SmartCommit results ...............................................'
  if python3 src/python/main/smartcommit_results_to_csv.py "${smartcommit_untangling_dir}/${project}_${vid}/${commit}" "$smartcommit_result_out"
  then
      echo 'Parsing SmartCommit results ............................................... OK'
  else
      echo -ne 'Parsing SmartCommit results ............................................. FAIL'
      untangle_exit_code=1
  fi
fi

# Retrieve untangling results from Flexeme and parse them into a CSV file.
echo ""

flexeme_result_out="${evaluation_dir}/flexeme.csv"
if [ -f "$flexeme_result_out" ] && [ $regenerate_results == false ]; then
  echo -ne 'Parsing Flexeme results ................................................. CACHED\r'
else
  echo 'Parsing Flexeme results ...............................................'
  if python3 src/python/main/flexeme_results_to_csv.py "$flexeme_untangling_graph" "$flexeme_result_out"
  then
      echo 'Parsing Flexeme results ................................................... OK'
  else
      echo -ne 'Parsing Flexeme results ................................................. FAIL\r'
      untangle_exit_code=1
  fi
fi
echo ""
exit $untangle_exit_code
