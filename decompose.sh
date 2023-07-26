#!/bin/bash
# Untangle with SmartCommit and Flexeme on a list of Defects4J (D4J) bugs.
# - $1: Path to the file containing the bugs to untangle.
# - $2: Path to the directory where the results are stored and repositories checked out.

# The decomposition results are written to ~/decomposition/smartcommit/<D4J bug>/ and ~/decomposition/<D4J bug>/flexeme/<D4J bug>/ subfolder.
# - flexeme/flexeme.dot: The PDG (untangling graph) generated by Flexeme
# - flexeme/time.csv: Run time allocated for untangling by Flexeme
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time allocated for untangling by SmartCommit

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: decompose.sh <bugs_file> <out_dir>'
    exit 1
fi

export bugs_file="$1" # The file containing the bugs to untangle.
export out_dir="$2" # The directory where the results are stored and repositories checked out.

if ! [ -f "$bugs_file" ]; then
    echo "$0: file ${bugs_file} not found. Exiting."
    exit 1
fi

mkdir -p "$out_dir"

set -o allexport
# shellcheck source=/dev/null
. .env
set +o allexport

if [ -z "${JAVA11_HOME}" ]; then
  echo "$0: Please set the JAVA11_HOME environment variable to a Java 11 installation."
  exit 1
fi

# Check that Java is 1.8 for Defects4J.
# Defects4J will use whatever is on JAVA_HOME.
java_version="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)"
if [ "$java_version" != "1.8" ] ; then
    echo "$0: please use Java 8 instead of ${java_version}"
    exit 1
fi

export workdir="${out_dir}/repositories"
export logs_dir="${out_dir}/logs"

mkdir -p "$workdir"
mkdir -p "$logs_dir"

echo "Parallelization jobs log will be stored in /tmp/decompose.log"
echo "Individual bug decomposition logs will be stored in ${logs_dir}/<project>_<bug_id>_decompose.log"
echo ""

export PYTHONHASHSEED=0
decompose_bug(){
  local project="$1"
  local vid="$2"
  export repository="${workdir}/${project}_${vid}"
  START="$(date +%s.%N)"   # Record start time for bug decomposition
  ./src/bash/main/decompose_bug.sh "$project" "$vid" "$out_dir" "$repository" > "${logs_dir}/${project}_${vid}_decompose.log" 2>&1
  ret_code=$?
  decomposition_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${decomposition_status_string}" "${ELAPSED}"
}

export -f decompose_bug
parallel --joblog /tmp/decompose.log --colsep "," decompose_bug {} < "$bugs_file"
