#!/bin/bash
# Untangle with SmartCommit and Flexeme on a list of Defects4J (D4J) bugs.
# - $1: Path to the file containing the bugs to untangle and evaluate.
# - $2: Path to the directory where the results are stored and repositories checked out.

# The decomposition results are written to ~/decomposition/smartcommit/<D4J bug>/ and ~/decomposition/<D4J bug>/flexeme/<D4J bug>/ subfolder.
# - flexeme/flexeme.dot: The PDG (untangling graph) generated by Flexeme
# - flexeme/time.csv: Run time allocated for untangling by Flexeme
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time allocated for untangling by SmartCommit

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 2 ]] ; then
    echo 'usage: evaluate_all.sh <bugs_file> <out_dir>'
    exit 1
fi

export bugs_file=$1 # Path to the file containing the bugs to untangle and evaluate.
export out_dir=$2 # Path to the directory where the results are stored and repositories checked out.

if ! [[ -f "$bugs_file" ]]; then
    echo "File ${bugs_file} not found. Exiting."
    exit 1
fi

mkdir -p "$out_dir"

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

if [[ -z "${JAVA_11}" ]]; then
  echo 'JAVA_11 environment variable is not set.'
  echo 'Please set it to the path of a Java 11 java.'
  exit 1
fi

# Check that Java is 1.8 for Defects4j.
# Defects4J will use whatever is on JAVA_HOME.
version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)
if [[ $(echo "$version != 1.8" | bc) == 1 ]] ; then
    echo "Unsupported Java Version: ${version}. Please use Java 8."
    exit 1
fi

export workdir="${out_dir}/repositories"
export logs_dir="${out_dir}/logs"

# export decomposition_path="${out_dir}/decomposition"
# export smartcommit_untangling_path="${out_dir}/decomposition/smartcommit"
# export flexeme_untangling_path="${decomposition_path}/flexeme"

mkdir -p "$workdir"
mkdir -p "$logs_dir"

echo "Logs stored in ${logs_dir}/<project>_<bug_id>.log"
echo ""

decompose_bug(){
  local project=$1
  local vid=$2
  export repository="${workdir}/${project}_${vid}"
  START=$(date +%s.%N)   # Record start time for bug decomposition
  ./src/bash/main/decompose.sh "$project" "$vid" "$out_dir" "$repository" &> "${logs_dir}/${project}_${vid}.log"
  ret_code=$?
  decomposition_status_string=$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")
  END=$(date +%s.%N)
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED=$(echo "$END - $START" | bc)
  printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${decomposition_status_string}" "${ELAPSED}"
}

export -f decompose_bug
parallel --colsep "," decompose_bug {} < "$bugs_file"