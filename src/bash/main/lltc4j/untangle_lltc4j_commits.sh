#!/bin/bash

# Untangle LLTC4J commits with a given untangling tool. The results are stored
# in the given results directory under 'evaluation/<commit_identifier>/'. In particular,
# the untangling results are stored in 'evaluation/<commit_identifier>/<tool_name>.csv'.
#
# Arguments:
# - $1: The CSV file containing the commits to untangle with header:
#       vcs_url,commit_hash,parent_hash
# - $2: The results directory where the untangling results will be stored.
#       The directory is expected to already contain the ground truth files for the commits.
#       The expected structure is:
#       <$2>/evaluation/<commit_identifier>/truth.csv
# - $3: The tool's name to use for untangling.
#       - 'smartcommit' to use SmartCommit.
#       - 'flexeme' to use Flexeme.
#       - 'filename' to use a file-based approach.
#
# Environment variables:
# - REMOVE_NON_CODE_CHANGES: If set to 'true', then the untangling tool will only
#   consider the code changes in the commit. Otherwise, it will consider all the
#   changes (e.g., documentation, whitespaces).
#
# Tool parameters:
# Tool-specific parameters are provided via environment variables. Run
# this script with the tool's name to see the required parameters.
# Example: untangle_lltc4j_commits.sh <commits_file> <results_dir> smartcommit
#
# This script outputs to stdout one line per LLTC4J commit with the following format:
#   <commit_identifier> <status> <time> [<log_file>]
# The <> denote a metavariable, and the [] are literal.
# - <commit_identifier>: Identify a commit. e.g.,'<project name>_<commit hash>'.
# - <status>: The result of the untangling. Possible values are:
#   - CACHED: The untangling results were already computed and cached.
#   - OK: The untangling tool succeeded.
#   - UNTANGLING_FAIL: The untangling tool failed.
#   - EXPORT_FAIL: The export of the untangling results failed.
#
# The script outputs to stderr the total elapsed time for the untangling process and
# a message indicating that the untangling for the given file and tool is complete for logging purposes.
#

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 3 ] ; then
    echo "usage: $0 <commits_csv_file> <results_dir> <tool_name>" >&2
    exit 1
fi

export commits_file="$1"
export results_dir="$2"
export tool_name="$3"

if ! [ -f "$commits_file" ]; then
    echo "$0: commit file ${commits_file} not found. Exiting." >&2
    exit 1
fi

if ! [ -d "$results_dir" ]; then
    echo "$0: directory ${results_dir} not found. Exiting." >&2
    exit 1
fi

export FLEXEME_TOOL="flexeme"
export SMARTCOMMIT_TOOL="smartcommit"
export FILE_TOOL="filename"
ALLOWED_TOOLS=("$FLEXEME_TOOL" "$SMARTCOMMIT_TOOL" "$FILE_TOOL")

if [[ ! " ${ALLOWED_TOOLS[*]} " == *" ${tool_name} "* ]]; then
    formatted_tools=$(printf "'%s', " "${ALLOWED_TOOLS[@]}")
    formatted_tools="${formatted_tools%, }" # Remove the trailing comma and space.
    echo "Invalid untangling tool: '$tool_name'." >&2
    echo "Allowed tools are: $formatted_tools" >&2
    exit 1
fi

# Check environment variables and load utility functions for LLTC4J.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPT_DIR/check-environment-lltc4j.sh"
. "$SCRIPT_DIR/lltc4j_util.sh"
set +o allexport

# Verify that the implementation for the selected tool exists.
tool_lib="$SCRIPT_DIR/tool_${tool_name}.sh"
if ! [ -f "$tool_lib" ]; then
    echo "Implementation '$tool_lib' for tool '$tool_name' not found." >&2
    exit 1
fi

# Verify that the script for the tool defines the required functions for an untangling tool.
# Required functions:
# - check_environment: Checks any pre-requisites for the tool to function.
#                      The function exits with an error if the tool's pre-requisites are not met.
# - has_untangling_output: Checks if the untangling tool has already produced an output for the given commit.
#                          The function return 0 if the untangling tool has already produced an output for the given commit.
#                          The function return 1 if the untangling tool has not already produced an output for the given commit.
# - untangle_commit: Untangles the given commit and stores the results in the given output directory.
#                    The function exits with an error if the untangling tool fails.
# - convert_untangling_output_to_csv: Converts the untangling output to the CSV format and stores it in the given output file.
#                                     The function exits with an error if the conversion fails.

# Remove previously existing functions to ensure the tool's implementation exists.
unset -f check_environment has_untangling_output untangle_commit convert_untangling_output_to_csv

# shellcheck source=/dev/null
. "$tool_lib"

if ! [[ $(type -t check_environment) == function ]]; then
  echo "Function 'check_environment' not found in '$tool_lib'." >&2
  exit 1
fi

check_environment

if ! [[ $(type -t has_untangling_output) == function ]]; then
  echo "Function 'has_untangling_output' not found in '$tool_lib'." >&2
  exit 1
fi
export -f has_untangling_output

if ! [[ $(type -t untangle_commit) == function ]]; then
  echo "Function 'untangle_commit' not found in '$tool_lib'." >&2
  exit 1
fi
export -f untangle_commit

if ! [[ $(type -t convert_untangling_output_to_csv) == function ]]; then
  echo "Function 'untangle_commit' not found in '$tool_lib'." >&2
  exit 1
fi
export -f convert_untangling_output_to_csv

export untangling_tool_output_dir="${results_dir}/decomposition/$tool_name"
mkdir -p "$untangling_tool_output_dir"

export logs_dir="${results_dir}/logs"
mkdir -p "$logs_dir"

export repositories_dir="${results_dir}/repositories"
mkdir -p "$repositories_dir"

# Clone a repository for a project if it isn't already present in $repositories_dir.
clone_repository() {
  local vcs_url="$1"
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"

  local project_repository_dir="${repositories_dir}/${project_name}"

  # Check if the repo for this project is already cloned.
  if git clone -q "$vcs_url" "$project_repository_dir" > /dev/null 2>&1; then
    echo "Cloned $vcs_url in $project_repository_dir." >&2
  fi
}
export -f clone_repository

# Clone all the repositories for the commits. This must be done before running
# the untangling tools in parallel because otherwise, it creates race conditions
# where untangling tools try to untangle commits for which their repository
# hasn't yet finished cloning.
tail -n+2 "$commits_file" | parallel --colsep "," clone_repository {}

# Untangle a commit from the LLTC4J dataset and save the untangling result in a CSV file.
# The tool to use for untangling and the output directory are provided in the surrounding
# scope of this function.
#
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_lltc4j_commit() {
  local vcs_url="$1"
  local commit_hash="$2"

  local project_name
  local commit_identifier
  project_name="$(get_project_name_from_url "$vcs_url")"
  commit_identifier="$(get_commit_identifier "$project_name" "$commit_hash")"

  # The directory where the repository for this project is stored.
  local project_repository_dir="${results_dir}/repositories/${project_name}"

  # The directory where the untangling results for this commit will be stored.
  local untangling_output_dir="$untangling_tool_output_dir/$commit_identifier"
  mkdir -p "$untangling_output_dir"

  # The directory where the untangling results for the tool will be stored and
  # where the ground truth is stored.
  local commit_result_dir="${results_dir}/evaluation/${commit_identifier}"
  local untangling_export_file="${commit_result_dir}/${tool_name}.csv"
  local ground_truth_file="${commit_result_dir}/truth.csv"

  # Log file for this commit. The log file contains all the output related to the
  # untangling process for this commit: checking out the commit,
  # verifying the ground truth, running the untangling tool, and exporting the
  # untangling results.
  local log_file="${logs_dir}/${commit_identifier}_${tool_name}.log"

  # Remove previous log file.
  rm -f "$log_file"

  status_string="OK"
  START="$(date +%s.%N)"

  # If the ground truth is missing, skip this commit.
  # TODO: Refactor into a function so it can return early. The status code can be determined by the function's return value.
  if ! [ -f "$ground_truth_file" ]; then
    echo "Ground truth file not found: ${ground_truth_file}" >> "$log_file" 2>&1
    status_string="GROUND_TRUTH_MISSING"
  else
    # TODO: Only do that if we need to untangle.
    # Copy the repository to a temporary directory to enable parallelization.
    # The temporary directory contains the commit identifier to facilitate
    # debugging.
    local tmp_repository_dir
    tmp_repository_dir="$(mktemp -d -t "${commit_identifier}.XXXXXX")"
    cp -r "$project_repository_dir"/. "$tmp_repository_dir"
    echo "Untangling in temporary directory: $tmp_repository_dir" >> "$log_file" 2>&1

    base_dir="$(pwd)"
    # Checkout the commit to untangle.
    cd "$tmp_repository_dir" >> "$log_file" 2>&1 || exit 1
    if ! git -c advice.detachedHead=false checkout "$commit_hash" >> "$log_file" 2>&1; then
      status_string="CHECKOUT_FAIL"
    fi
    cd - >> "$log_file" 2>&1 || exit 1
  fi

  # Clean repo if flag $REMOVE_NON_CODE_CHANGES is set to true.
  if [ "$REMOVE_NON_CODE_CHANGES" = true ] && [ "$status_string" = "OK" ]; then
    echo "Untangling on code changes only." >> "$log_file" 2>&1

    cd "$tmp_repository_dir" > /dev/null 2>&1
    # Resets the current branch up to this commit.
    git reset -q --hard "$commit_hash" >> "$log_file" 2>&1
    # Remove the non-code changes.
    "$SCRIPT_DIR/clean_lltc4j_repo.sh" >> "$log_file" 2>&1
    cd - > /dev/null 2>&1

    # Running cd again is necessary to refresh the directory content otherwise
    # git throws an error. See https://stackoverflow.com/a/70612805
    cd "$tmp_repository_dir" > /dev/null 2>&1

    # Update the commit to untangle to the version without non-code changes.
    revision_clean_fixed=$(git rev-parse HEAD)
    commit_hash="$revision_clean_fixed"

    cd "$base_dir"
  else
    echo "Untangling on all changes (not just code changes)." >> "$log_file" 2>&1
  fi

  # TODO: Refactor into a function so it can return early. The status code can be
  #       determined by the function's return value.
  if [ "$status_string" == "OK" ]; then

    # Untangle the commit if the exported untangling results for this commit do not exist.
    if [ -f "$untangling_export_file" ]; then
      status_string="CACHED"
    elif has_untangling_output "$untangling_output_dir" "$project_name" "$commit_hash" >> "$log_file" 2>&1 || untangle_commit "$tmp_repository_dir" "$ground_truth_file" "$commit_hash" "$commit_identifier" "$untangling_output_dir" >> "$log_file" 2>&1; then
      status_string="UNTANGLING_SUCCESS"
    else
      status_string="UNTANGLING_FAIL"
    fi

    # If the untangling tool produced an output, then export it to the CSV format.
    if [ "$status_string" == "UNTANGLING_SUCCESS" ]; then
      if convert_untangling_output_to_csv "$untangling_output_dir" "$untangling_export_file" "$(basename "$tmp_repository_dir")" "$commit_hash" >> "$log_file" 2>&1; then
        status_string="OK"
      else
        status_string="EXPORT_FAIL"
      fi
    fi
  fi

  rm -rf "$tmp_repository_dir"

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %-20s %.0fs [%s]\n" "${commit_identifier}" "${status_string}" "${ELAPSED}" "${log_file}"
}

export -f untangle_lltc4j_commit

START_TIME=$(date +%s)
# Reads the commits file, ignoring the CSV header, and untangles each commit in parallel.
tail -n+2 "$commits_file" | parallel --colsep "," untangle_lltc4j_commit {}
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
ELAPSED_TIME_FORMATTED=$(date -u -d @"${ELAPSED_TIME}" +"%H:%M:%S")

echo "" >&2
echo "Untangled commits in ${commits_file} with tool '${tool_name}'." >&2
echo "Total elapsed time: ${ELAPSED_TIME_FORMATTED}." >&2
