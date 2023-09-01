#!/bin/bash
# Computes 7 commit metrics for a list of Defects4J (D4J) bugs.
# Aggregates commit across all bug files into 1 metrics.csv file.
# - $1: Path to the file containing the bugs to untangle.
# - $2: Path to the directory where the results are stored and repositories checked out.
# Writes aggregated results to untangling-eval/metrics.csv.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

DEBUG=
# DEBUG=YES

if [ $# -ne 2 ] ; then
    echo 'usage: compute_metrics.sh <bugs_file> <out_dir>'
    exit 1
fi

export bugs_file="$1" # The file containing the bugs to untangle.
export out_dir="$2" # The directory where the results are stored and repositories checked out.

if ! [ -f "$bugs_file" ]; then
    echo "$0: file ${bugs_file} not found. Exiting."
    exit 1
fi
export workdir="${out_dir}/repositories"
export metrics_dir="${out_dir}/metrics" # Path containing the commit metrics.
export logs_dir="${out_dir}/logs" # Path containing the commit metrics.

mkdir -p "$workdir"
mkdir -p "${metrics_dir}"
mkdir -p "${logs_dir}"

echo "$0: logs will be stored in ${logs_dir}/<project>_<bug_id>_metrics.log"
if [ -n "${DEBUG}" ] ; then
  echo "Contents of ${logs_dir}:"
  ls -al "${logs_dir}"
fi
echo ""

generate_commit_metrics() {
  local project="$1"
  local vid="$2"
  export repository="${workdir}/${project}_${vid}"
  START="$(date +%s.%N)"  # Record start time for bug commit metrics generation
  
  if [ -n "${DEBUG}" ] ; then
    echo "about  to call: ./src/bash/main/get_metrics_bug.sh $project $vid $out_dir $repository > ${logs_dir}/${project}_${vid}_metrics.log"
  fi
  ./src/bash/main/get_metrics_bug.sh "$project" "$vid" "$out_dir" "$repository" > "${logs_dir}/${project}_${vid}_metrics.log" 2>&1
  ret_code=$?
  metrics_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (time: %.0fs)\n" "${project}_${vid}" "${metrics_status_string}" "${ELAPSED}"
}

export -f generate_commit_metrics
parallel --colsep "," generate_commit_metrics {} < "$bugs_file"

if [ -n "${DEBUG}" ] ; then
  echo "Contents of logs_dir ${logs_dir}:"
  ls -al "${logs_dir}"
  echo "Contents of metrics_dir ${metrics_dir}:"
  ls -al "${metrics_dir}"
fi

metrics_results="${out_dir}/metrics.csv"

echo "project,vid,files_updated,test_files_updated,hunks,average_hunk_size,code_changed_lines,noncode_changed_lines,tangled_lines,tangled_hunks" > "$metrics_results"
cat "${metrics_dir}"/*.csv >> "$metrics_results"
echo ""
echo "Commit metrics were aggregated and saved in ${metrics_results}"
