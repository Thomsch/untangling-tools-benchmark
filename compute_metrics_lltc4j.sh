#!/bin/bash
# Computes 7 commit metrics for a list of LLTC4J bugs.
# Aggregates commit across all bug files into 1 metrics.csv file.
# Arguments:
# - $1: The file containing the commits to calculate the metrics for.
# - $2: The directory where the results are stored and repositories checked results.
# Writes aggregated results to untangling-eval/metrics.csv.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

DEBUG=
# DEBUG=YES

if [ $# -ne 2 ] ; then
    echo 'usage: compute_metrics.sh <commits_file> <results_dir>'
    exit 1
fi

export commits_file="$1" # The file containing the bugs to untangle.
export results_dir="$2" # The directory where the results are stored and repositories checked results.

if ! [ -f "$commits_file" ]; then
    echo "$0: file ${commits_file} not found. Exiting."
    exit 1
fi
export workdir="${results_dir}/repositories"
export metrics_dir="${results_dir}/metrics" # Path containing the commit metrics.
export logs_dir="${results_dir}/logs" # Path containing the commit metrics.

mkdir -p "$workdir"
mkdir -p "${metrics_dir}"
mkdir -p "${logs_dir}"

echo "$0: logs will be stored in ${logs_dir}/<project>_<bug_id>_metrics.log"
if [ -n "${DEBUG}" ] ; then
  echo "Contents of ${logs_dir}:"
  ls -al "${logs_dir}"
fi
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPT_DIR/src/bash/main/lltc4j/lltc4j_util.sh"

generate_commit_metrics() {
  local vcs_url="$1"
  local commit_hash="$2"
  local parent_hash="$3"

  local project_name
  project_name=$(get_project_name_from_url "$vcs_url")
  local short_commit_hash="${commit_hash:0:6}"

  local repository="${workdir}/${project_name}"

  local log_file
  log_file="${logs_dir}/${project_name}_${short_commit_hash}_metrics.log"
  local metrics_csv="${metrics_dir}/${project_name}_${short_commit_hash}.csv"

  START="$(date +%s.%N)"

  if ! [ -d "${repository}" ] ; then
    status_string="CLONE_NOT_FOUND"
  elif [ -f "$metrics_csv" ]; then
    status_string="CACHED"
  else
      diff_file="${repository}/VC_${short_commit_hash}.diff"
      git --git-dir "${repository}/.git" diff -U0 "$parent_hash".."$commit_hash" > "${diff_file}" 2> "$log_file"
      ret_code=$?
      if [ $ret_code -eq 0 ]; then
         if python3 src/python/main/diff_metrics_lltc4j.py "${diff_file}" "${project_name}" "${short_commit_hash}" > "$metrics_csv"; then
             status_string="OK"
         else
             status_string="METRIC_FAIL"
             rm -f "$metrics_csv"
         fi
      else
          status_string="DIFF_FAIL"
      fi
  fi
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (time: %.0fs) [%s]\n" "${project_name}_${short_commit_hash}" "${status_string}" "${ELAPSED}" "${log_file}"
}

export -f generate_commit_metrics
tail -n+2 "$commits_file" | parallel --colsep "," generate_commit_metrics {}

if [ -n "${DEBUG}" ] ; then
  echo "Contents of logs_dir ${logs_dir}:"
  ls -al "${logs_dir}"
  echo "Contents of metrics_dir ${metrics_dir}:"
  ls -al "${metrics_dir}"
fi

metrics_results="${results_dir}/metrics.csv"

echo "project,vid,files_updated,test_files_updated,hunks,average_hunk_size,code_changed_lines,noncode_changed_lines,tangled_lines,tangled_hunks" > "$metrics_results"
cat "${metrics_dir}"/*.csv >> "$metrics_results"
echo ""
echo "Commit metrics were aggregated and saved in ${metrics_results}"
