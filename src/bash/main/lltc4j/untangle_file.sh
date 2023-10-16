#!/bin/bash
# Untangle commits from LLTC4J using the file-based approach.
# Arguments:
# - $1: The file containing the commits to untangle.
# - $3: The root directory where the ground truth results are stored.

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
    echo "$0: file ${commits_file} not found. Exiting."
    exit 1
fi

if ! [ -d "$results_dir" ]; then
    echo "$0: directory ${results_dir} not found. Exiting."
    echo "Please generate the ground truth first."
    exit 1
fi

set -o allexport
. ./check-environment-lltc4j.sh
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
untangle_with_tools(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"

  local log_file="${logs_dir}/${project_name}_${short_commit_hash}_file_untangling.log"
  local ground_truth_file="${results_dir}/evaluation/${project_name}_${short_commit_hash}/truth.csv"
  local result_dir="${results_dir}/evaluation/${project_name}_${short_commit_hash}" # Directory where the parsed untangling results are stored.
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
    echo -ne 'Untangling with file-based approach ..................................\r' >> "$log_file"
    if python3 src/python/main/filename_untangling.py "${ground_truth_file}" "${file_untangling_out}" >> "$log_file" 2>&1 ;
    then
        echo 'Untangling with file-based approach .................................. OK' >> "$log_file"
        untangling_status_string="OK"
    else
        echo -ne 'Untangling with file-based approach .................................. FAIL\r' >> "$log_file"
        untangling_status_string="FAIL"
    fi
  fi

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%-20s %-20s (time: %.0fs) [%s]\n" "${project_name}_${short_commit_hash}" "${untangling_status_string}" "${ELAPSED}" "${log_file}"
}

export -f get_project_name_from_url
export -f untangle_with_tools

tail -n+2 "$commits_file" | parallel --colsep "," untangle_with_tools {}

echo "Untangling completed."
