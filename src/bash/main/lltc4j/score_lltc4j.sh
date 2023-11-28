#!/bin/bash
# Given a list of LLTC4J commits, the script scores the untangling results produced
# by the untangling tools and aggregate them in <ROOT_DIR>/evaluation/decomposition_scores.csv.
# The script has the following assumptions:
# - The untangling results are stored in <ROOT_DIR>/evaluation/<project_name>_<commit_hash>/<toolname>.csv.
# - The ground truth is stored in <ROOT_DIR>/evaluation/<project_name>_<commit_hash>/ground_truth.csv.
#
# Arguments:
# - $1: The file containing the commits to untangle.
# - $2: The root directory where the untangling results are stored and the ground truth is stored.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: score_lltc4j.sh <commits_file> <results_dir>'
    exit 1
fi

export commits_file="$1" # The file containing the commits to score.
export results_dir="$2" # The directory where the results are stored and repositories checked out.

export aggregate_scores_file="${results_dir}/decomposition_scores.csv" # Aggregated results.
export workdir="${results_dir}/repositories"
export evaluation_root_dir="${results_dir}/evaluation"
export decomposition_dir="${results_dir}/decomposition"
export logs_dir="${results_dir}/logs"

mkdir -p "$evaluation_root_dir"
mkdir -p "$decomposition_dir"
mkdir -p "$logs_dir"

# Load util functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPT_DIR/lltc4j_util.sh"

score_bug(){
  local vcs_url="$1"
  local commit_hash="$2"

  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"

  local short_commit_hash
  short_commit_hash="${commit_hash:0:6}"

  local evaluation_dir
  evaluation_dir="${evaluation_root_dir}/${project_name}_${short_commit_hash}"
  mkdir -p "$evaluation_dir"

  START="$(date +%s.%N)"  # Record start time for bug scoring

  python3 src/python/main/untangling_score.py "$evaluation_dir" "${project_name}" "${short_commit_hash}" > "${evaluation_dir}/scores.csv" 2> "${logs_dir}/${project_name}_${short_commit_hash}_score.log"
  ret_code=$?
  scoring_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%-20s %s (time: %.0fs) [%s]\n" "${project_name}_${short_commit_hash}" "${scoring_status_string}" "${ELAPSED}" "${logs_dir}/${project_name}_${short_commit_hash}_score.log"
}

export -f score_bug
# Reads the commits file, ignoring the CSV header, and score each commit in parallel.
tail -n+2 "$commits_file" | parallel --colsep "," score_bug {}

if ! cat "${evaluation_root_dir}"/*/scores.csv > "$aggregate_scores_file" ; then
  echo "No \"scores.csv\" files found under ${evaluation_root_dir}."
  find "${evaluation_root_dir}"
  exit 1
fi
echo ""
echo "Decomposition scores are aggregated in ${aggregate_scores_file}"
