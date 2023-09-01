#!/bin/bash
# Generates the ground truth using the original fix and the minimized version for a list of Defects4J (D4J) bugs.
# - $1: Path to the file containing the bugs to untangle.
# - $2: Path to the directory where the results are stored and repositories checked out.

# Writes the ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
# - CSV header: {file, source, target, group}
#     - file: The relative file path from the project root for a change
#     - source: The line number of the change if the change is a deletion
#     - target: The line number of the change if the change is an addition
#     - group: 'fix' if the change is a fix, 'other' if the change is a non bug-fixing change

# set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: generate_ground_truth.sh <bugs_file> <out_dir>'
    exit 1
fi

# Check that Java is 1.8 for Defects4J.
# Defects4J will use whatever is on JAVA_HOME.
java_version="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)"
if [ "$java_version" != "1.8" ] ; then
    echo "$0: please use Java 8 instead of ${java_version}"
    exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/env.sh
set +o allexport

. "$SCRIPTDIR"/src/bash/main/d4j_utils.sh

export bugs_file="$1" # The file containing the bugs to untangle.
export out_dir="$2" # The directory where the results are stored and repositories checked out.

if ! [ -f "$bugs_file" ]; then
    echo "$0: file ${bugs_file} not found. Exiting."
    exit 1
fi

export workdir="${out_dir}/repositories"
export evaluation_dir="${out_dir}/evaluation"
export logs_dir="${out_dir}/logs"

mkdir -p "$workdir"
mkdir -p "$evaluation_dir"
mkdir -p "$logs_dir"

echo "Logs stored in ${logs_dir}/<project>_<bug_id>_ground_truth.log"
echo ""

generate_truth_for_bug() {
  local project="$1"
  local vid="$2"

  export repository="${workdir}/${project}_${vid}"
  START="$(date +%s.%N)"  # Record start time for bug ground truth generation
  
  ./src/bash/main/ground_truth_bug.sh "$project" "$vid" "$out_dir" "$repository" > "${logs_dir}/${project}_${vid}_ground_truth.log" 2>&1
  ret_code=$?
  truth_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${truth_status_string}" "${ELAPSED}"
}

export -f generate_truth_for_bug
parallel --colsep "," generate_truth_for_bug {} < "$bugs_file"
