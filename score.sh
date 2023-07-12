#!/bin/bash
# Given a list of Defects4J (D4J) bugs, the script translates SmartCommit results (JSON files) and Flexeme graphs ().dot files) in decomposition/D4J_bug for each D4J bug
# file to the line level. Each line is labelled with the group it belongs to and this is reported in
# a readable CSV file. Then, calculates the Rand Index for untangling results of 3 methods: SmartCommit, Flexeme, and File-based.
# - $1: Path to the file containing the bugs to untangle and evaluate.
# - $2: Path to the directory where the results are stored and repositories checked out.

# Results are outputted to evaluation/<D4J_bug> respective subfolder.
# Writes parsed decomposition results to smartcommit.csv and flexeme.csv for each bug in /evaluation/<D4J_bug>
# Writes Rand Index scores computed to /evaluation/<D4J_bug>/decomposition_scores.csv

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
. .env
set +o allexport

export bugs_file="$1" # Path to the file containing the bugs to untangle and evaluate.
export out_dir="$2" # Path to the directory where the results are stored and repositories checked out.

if [[ $# -ne 2 ]] ; then
    echo 'usage: score.sh <bugs_file> <out_dir>'
    exit 1
fi

export out_file="${out_dir}/decomposition_scores.csv" # Aggregated results.
export workdir="${out_dir}/repositories"
export evaluation_dir="${out_dir}/evaluation"
export decomposition_dir="${out_dir}/decomposition"
export logs_dir="${out_dir}/logs"

mkdir -p "$evaluation_dir"
mkdir -p "$decomposition_dir"
mkdir -p "$logs_dir"

echo "Logs stored in ${logs_dir}/<project>_<bug_id>_score.log"
echo ""

parse_and_score_bug(){
  local project="$1"
  local vid="$2"

  export repository="${workdir}/${project}_${vid}"
  START="$(date +%s.%N)"  # Record start time for bug scoring
  
  ./src/bash/main/score.sh "$project" "$vid" "$out_dir" "$repository" > "${logs_dir}/${project}_${vid}_score.log" 2>&1
  ret_code=$?
  scoring_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${scoring_status_string}" "${ELAPSED}"
}

export -f parse_and_score_bug
parallel --colsep "," parse_and_score_bug {} < "$bugs_file"

cat "${evaluation_dir}"/*/scores.csv > "$out_file"
echo ""
echo "Decomposition scores aggregated and saved in ${out_file}"