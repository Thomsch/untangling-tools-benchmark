#!/bin/bash
# Untangle with SmartCommit and Flexeme on one  Defects4J (D4J) bug.
# - $1: D4J Project name
# - $2: D4J Bug Id
# - $3: Path where the results are stored.
# - $4: Path where the repo is checked out

# The decomposition results are written to ~/decomposition/smartcommit/<D4J bug>/ and ~/decomposition/<D4J bug>/flexeme/<D4J bug>/ subfolder.
# - flexeme/flexeme.dot: The PDG (untangling graph) generated by Flexeme
# - flexeme/time.csv: Run time allocated for untangling by Flexeme
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time allocated for untangling by SmartCommit

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 4 ]] ; then
    echo 'usage: ./decompose.sh <project> <vid> <out_dir> <repository>'
    exit 1
fi

project=$1
vid=$2
out_dir=$3
repository=$4

echo -ne '\n'
echo "Decompositing project $project, bug $vid, repository $repository"

# Checkout Defects4J bug
mkdir -p "$repository"
defects4j checkout -p "$project" -v "$vid"b -w "$repository"

# Local variables
export evaluation_path="${out_dir}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground
# truth, decompositions in CSV format.
export decomposition_path="${out_dir}/decomposition"
export smartcommit_untangling_path="${out_dir}/decomposition/smartcommit"
export flexeme_untangling_path="${decomposition_path}/flexeme"

mkdir -p "$evaluation_path"
mkdir -p "$decomposition_path"
mkdir -p "$smartcommit_untangling_path"
mkdir -p "$flexeme_untangling_path"

# Get commit hash
commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)

# Get source path and class path
sourcepath=$(defects4j export -p dir.src.classes -w "${repository}")
sourcepath="${sourcepath}:$(defects4j export -p dir.src.tests -w "${repository}")"
classpath=$(defects4j export -p cp.compile -w "${repository}")
classpath="${classpath}:$(defects4j export -p cp.test -w "${repository}")"

echo -ne '\n'
echo -ne 'Untangling with SmartCommit ...............................................\r' 
smartcommit_untangling_results="${smartcommit_untangling_path}/${project}_${vid}/${commit}"

# Untangle with SmartCommit
if [[ -d "$smartcommit_untangling_results" ]]; then
  echo -ne 'Untangling with SmartCommit ............................................. CACHED\r'
  regenerate_results=false
else
  echo -ne '\n'
  START_DECOMPOSITION=$(date +%s.%N)
  $JAVA_11 -jar bin/smartcommitcore-1.0-all.jar -r "$repository" -c "$commit" -o "$smartcommit_untangling_path"
  END_DECOMPOSITION=$(date +%s.%N)
  DIFF_DECOMPOSITION=$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)
  echo "${project},${vid},smartcommit,${DIFF_DECOMPOSITION}" > "${smartcommit_untangling_results}/time.csv"
  echo -ne 'Untangling with SmartCommit ............................................... OK'
  regenerate_results=true
fi

# Untangle with Flexeme
echo -ne '\n'
echo -ne 'Untangling with Flexeme ...............................................\r'

flexeme_untangling_results="${flexeme_untangling_path}/${project}_${vid}"
flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"

if [[ -f "$flexeme_untangling_graph" ]]; then
  echo -ne 'Untangling with Flexeme ................................................. CACHED\r'
  regenerate_results=false
else
  echo -ne '\n'
  mkdir -p "$flexeme_untangling_results"
  START_DECOMPOSITION=$(date +%s.%N)
  ./src/bash/main/untangle_flexeme.sh "$repository" "$commit" "$sourcepath" "$classpath" "${flexeme_untangling_graph}" &> "${logs_dir}/${project}_${vid}.log"
  flexeme_untangling_code=$?
  if [ $flexeme_untangling_code -eq 0 ]
  then
    echo -ne 'Untangling with Flexeme ................................................... OK'
    regenerate_results=true
  else
    echo -ne 'Untangling with Flexeme ................................................. FAIL'
    regenerate_results=false
  fi
  END_DECOMPOSITION=$(date +%s.%N)
  DIFF_DECOMPOSITION=$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)
  echo "${project},${vid},flexeme,${DIFF_DECOMPOSITION}" > "${flexeme_untangling_results}/time.csv"
fi
echo -ne '\n'
