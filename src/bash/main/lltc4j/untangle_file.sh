#!/bin/bash
# Untangle commits from LLTC4J using the file-based approach.
# Arguments:
# - $1: The file containing the commits to untangle in CSV format with header:
#       vcs_url, commit_hash, parent_hash
# - $3: The root directory where the results are stored.

# The untangling results are stored in $results_dir/evaluation/<commit>/
# - file_untangling.csv: The untangling results in CSV format.

set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo "usage: $0 <commits_file> <results_dir>"
    exit 1
fi

export commits_file="$1" # The file containing the commits to untangle.
export results_dir="$2" # The directory where the results are stored and repositories checked out.

if ! [ -f "$commits_file" ]; then
    echo "$0: commit file ${commits_file} not found. Exiting."
    exit 1
fi

if ! [ -d "$results_dir" ]; then
    echo "$0: directory ${results_dir} not found. Exiting."
    echo "Please generate the ground truth first."
    exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPT_DIR/../../../../check-environment-lltc4j.sh"
set +o allexport

java_version="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)"
if [ "$java_version" != "1.8" ] ; then
    echo "$0: please use Java 8 instead of ${java_version}"
    exit 1
fi

export workdir="${results_dir}/repositories"
export logs_dir="${results_dir}/logs"

mkdir -p "$workdir"
mkdir -p "$logs_dir"

export PYTHONHASHSEED=0
export SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPT_DIR/lltc4j_util.sh"

# Untangles a commit from the LLTC4J dataset using the file-based approach.
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_file_baseline(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"
  commit_identifier="${project_name}_${short_commit_hash}"

  local log_file="${logs_dir}/${commit_identifier}_file_untangling.log"
  local result_dir="${results_dir}/evaluation/${commit_identifier}" # Directory where the parsed untangling results are stored.
  local ground_truth_file="${result_dir}/truth.csv"
  local file_untangling_out="${result_dir}/file_untangling.csv"

  mkdir -p "$result_dir"

  START="$(date +%s.%N)"

  # If the ground truth is missing, skip this commit.
  if ! [ -f "$ground_truth_file" ]; then
    untangling_status_string="MISSING_GROUND_TRUTH"
    echo "Missing ground truth for ${project_name}_${short_commit_hash}. Skipping." >> "$log_file"
  elif [ -f "$file_untangling_out" ]; then
    echo 'Untangling with file-based approach .................................. CACHED' >> "$log_file"
    untangling_status_string="CACHED"
  else
    echo 'Untangling with file-based approach ..................................' >> "$log_file"
    if python3 src/python/main/filename_untangling.py "${ground_truth_file}" "${file_untangling_out}" >> "$log_file" 2>&1 ;
    then
        untangling_status_string="OK"
    else
        untangling_status_string="FAIL"
    fi
    echo "Untangling with file-based approach .................................. ${untangling_status_string}" >> "$log_file"
  fi

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%-20s %-20s (time: %.0fs) [%s]\n" "${commit_identifier}" "${untangling_status_string}" "${ELAPSED}" "${log_file}"
}

export -f get_project_name_from_url
export -f untangle_file_baseline

tail -n+2 "$commits_file" | parallel --colsep "," untangle_file_baseline {}

echo "Untangling completed."
