#!/bin/bash
# Computes 7 commit metrics for a list of Defects4J (D4J) bugs.
# Aggregates commit across all bug files into 1 metrics.csv file.
# - $1: Path to the file containing the bugs to untangle and evaluate.
# - $2: Path to the directory where the results are stored and repositories checked out.
# Writes aggregated results to untangling-eval/metrics.csv.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: ground_truth.sh <bugs_file> <out_dir>'
    exit 1
fi

export bugs_file="$1" # Path to the file containing the bugs to untangle and evaluate.
export out_dir="$2" # Path to the directory where the results are stored and repositories checked out.

if ! [ -f "$bugs_file" ]; then
    echo "File ${bugs_file} not found. Exiting."
    exit 1
fi

export metrics_dir="${out_dir}/metrics" # Path containing the commit metrics.

mkdir -p "${metrics_dir}"

echo "Logs stored in ${logs_dir}/<project>_<bug_id>_get_metrics.log"
echo ""

generate_commit_metrics() {
  local project="$1"
  local vid="$2"
  export repository="${workdir}/${project}_${vid}"
  START="$(date +%s.%N)"  # Record start time for bug commit metrics generation
  
  ./src/bash/main/get_metrics_bug.sh "$project" "$vid" "$out_dir" "$repository" > "${logs_dir}/${project}_${vid}_get_metrics.log" 2>&1
  ret_code=$?
  truth_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${truth_status_string}" "${ELAPSED}"
}

export -f generate_commit_metrics
parallel --colsep "," generate_commit_metrics {} < "$bugs_file"

metrics_results="${out_dir}/metrics.csv"
cat "${metrics_dir}"/*.csv > "$metrics_results"
echo ""
echo "Commit metrics aggregated and saved in ${metrics_results}"