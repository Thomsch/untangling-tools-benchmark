#!/bin/bash
# Generates 3 diffs and 3 source code versions for a a list of Defects4J bugs.
# - $1: Path to the file containing the bugs to untangle and evaluate.
# - $2: Path to the directory where the results are stored and repositories checked out.

# Writes 3 unified diffs to the checked out bug to repo /<project><id>/diffs and 3 source code artifacts to the D4J project repository
# - VC.diff: Version Control diff
# - BF.diff: Bug-fixing diff
# - NBF.diff: Non bug-fixing diff
# - original.java: The buggy source code in version control
# - buggy.java: The buggy source code after all non-bug fixes are applied
# - fixed.java: The fixed source code in version control

# set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: generate_artifacts.sh <bugs_file> <out_dir>'
    exit 1
fi

export bugs_file="$1" # Path to the file containing the bugs to untangle and evaluate.
export out_dir="$2" # Path to the directory where the results are stored and repositories checked out.

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/env.sh
set +o allexport

# Check that Java is 1.8 for Defects4j.
# Defects4J will use whatever is on JAVA_HOME.
version="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)"
if [ "$version" != "1.8" ] ; then
    echo "Unsupported Java Version: ${version}. Please use Java 8."
    exit 1
fi

export workdir="${out_dir}/repositories"
export logs_dir="${out_dir}/logs"

mkdir -p "$workdir"
mkdir -p "$logs_dir"

echo "Logs stored in ${logs_dir}/<project>_<bug_id>_artifacts.log"
echo ""

generate_artifacts_for_bug() {
  local project="$1"
  local vid="$2"

  export repository="${workdir}/${project}_${vid}"
  START="$(date +%s.%N)"  # Record start time for bug ground truth generation
  
  ./src/bash/main/generate_artifacts_bug.sh "$project" "$vid" "$repository" > "${logs_dir}/${project}_${vid}_artifacts.log" 2>&1
  ret_code=$?
  artifacts_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${artifacts_status_string}" "${ELAPSED}"
}

export -f generate_artifacts_for_bug
parallel --colsep "," generate_artifacts_for_bug {} < "$bugs_file"
