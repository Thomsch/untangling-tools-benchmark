#!/bin/bash
# Given a list of Defects4J (D4J) bugs, the script scores untangling
# results in decomposition/<D4J_BUGID> subfolders.
# Arguments:
# - $1: The file containing the bugs to untangle.
# - $2: The directory where the results are stored.

# Results are outputted to evaluation/<D4J_bug> respective subfolder.
# Writes parsed decomposition results to smartcommit.csv and flexeme.csv for each bug in evaluation/<D4J_bug>.
# Writes Rand Index scores computed to evaluation/decomposition_scores.csv.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/check-environment.sh
set +o allexport

if [ $# -ne 2 ] ; then
    echo 'usage: score.sh <bugs_file> <out_dir>'
    exit 1
fi

export bugs_file="$1" # The file containing the bugs to untangle.
export out_dir="$2" # The directory where the results are stored and repositories checked out.


export out_file="${out_dir}/decomposition_scores.csv" # Aggregated results.
export workdir="${out_dir}/repositories"
export evaluation_dir="${out_dir}/evaluation"
export decomposition_dir="${out_dir}/decomposition"
export logs_dir="${out_dir}/logs"

mkdir -p "$evaluation_dir"
mkdir -p "$decomposition_dir"
mkdir -p "$logs_dir"

echo "$0: logs will be stored in ${logs_dir}/<project>_<bug_id>_score.log"
echo ""

score_bug(){
  local project="$1"
  local vid="$2"

  export repository="${workdir}/${project}_${vid}"
  START="$(date +%s.%N)"  # Record start time for bug scoring
  
  ./src/bash/main/score_bug.sh "$project" "$vid" "$out_dir" "$repository" > "${logs_dir}/${project}_${vid}_score.log" 2>&1
  ret_code=$?
  scoring_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (time: %.0fs)\n" "${project}_${vid}" "${scoring_status_string}" "${ELAPSED}"
}

export -f score_bug
parallel --colsep "," score_bug {} < "$bugs_file"

if ! cat "${evaluation_dir}"/*/scores.csv > "$out_file" ; then
  echo "No \"scores.csv\" files found under ${evaluation_dir}."
  find "${evaluation_dir}"
  exit 1
fi
echo ""
echo "Decomposition scores were aggregated and saved in ${out_file}"
