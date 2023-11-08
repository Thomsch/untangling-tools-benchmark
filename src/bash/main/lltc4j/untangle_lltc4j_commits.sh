#!/bin/bash

# Untangle LLTC4J commits with a given untangling tool. The results are stored
# the results directory under 'evaluation/<commit>/'. The untangling results
# are stored in CSV format in 'evaluation/<commit>/<tool_name>.csv'.
#
# Arguments:
# - $1: The file containing the commits to untangle with header:
#       vcs_url,commit_hash,parent_hash
# - $2: The results directory where the ground truth results are stored.
# - $3: The tool's name to use for untangling.
#       - 'smartcommit' to use SmartCommit.
#       - 'flexeme' to use Flexeme.
#       - 'file' to use a naive file-based approach.
#
# Tool specific arguments are provided via environment variables. Run
# this script with the tool's name to see the required arguments.
#
# The result of each untangling process is output to stdout in the following
# format: <commit_identifier> <status> (time: <time>) [<log_file>].
# - <commit_identifier>: The identifier of the commit being untangled.
# - <status>: The status of the untangling process. Possible values are:
#   - CACHED: The untangling results were already computed and cached.
#   - OK: The untangling process succeeded.
#   - UNTANGLING_FAIL: The untangling process failed.
#   - EXPORT_FAIL: The export of the untangling results failed.
#
# Logging and errors messages are written to stderr.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 3 ] ; then
    echo "usage: $0 <commits_file> <results_dir> <tool_name>" >&2
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
    echo "Please generate the ground truth first." >&2
    exit 1
fi

export FLEXEME_TOOL="flexeme"
export SMARTCOMMIT_TOOL="smartcommit"
export FILE_TOOL="file"
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

# Verify that the script for the tool exists.
script_for_tool="$SCRIPT_DIR/tool_$tool_name.sh"
if ! [ -f "$script_for_tool" ]; then
    echo "Script for tool '$tool_name' not found: '$script_for_tool'." >&2
    exit 1
fi

# Verify that the script for the tool defines the required functions for an untangling tool.
# Required functions:
# - check_environment: Checks any pre-requisites for the tool to function. The function should exit with an error if the pre-requisites are not met.

# shellcheck source=/dev/null
. "$script_for_tool"

if ! [[ $(type -t check_environment) == function ]]; then
  echo "Function 'check_environment' not found in '$script_for_tool'." >&2
  exit 1
fi

check_environment

if ! [[ $(type -t has_untangling_output) == function ]]; then
  echo "Function 'has_untangling_output' not found in '$script_for_tool'." >&2
  exit 1
fi
export -f has_untangling_output

if ! [[ $(type -t untangle_commit) == function ]]; then
  echo "Function 'untangle_commit' not found in '$script_for_tool'." >&2
  exit 1
fi
export -f untangle_commit

if ! [[ $(type -t export_untangling_output) == function ]]; then
  echo "Function 'untangle_commit' not found in '$script_for_tool'." >&2
  exit 1
fi
export -f export_untangling_output

export untangling_tool_output_dir="${results_dir}/decomposition/$tool_name"
mkdir -p "$untangling_tool_output_dir"

export logs_dir="${results_dir}/logs"
mkdir -p "$logs_dir"

# Clone missing directories. Needs to be done before running the untangling process otherwise
# some processes will think the repository has been cloned when it hasn't finished cloning yet.
clone_repository() {
  local vcs_url="$1"
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"

  local project_repository_dir="${results_dir}/repositories/${project_name}"

  # Check if the repo for this project is already cloned.
  if git clone -q "$vcs_url" "$project_repository_dir" > /dev/null 2>&1; then
    echo "Cloned $vcs_url in $project_repository_dir because it didn't exist yet." >&2
  fi
}
export -f clone_repository
export repositories_directory="${results_dir}/repositories"
mkdir -p "$repositories_directory"
tail -n+2 "$commits_file" | parallel --colsep "," clone_repository {}


#mkdir -p "$results_dir" # Create the root directory if it doesn't exists yet.

#export smartcommit_untangling_root_dir="${results_dir}/decomposition/smartcommit"
#export flexeme_untangling_dir="${results_dir}/decomposition/flexeme"
#export smartcommit_result_dir="${smartcommit_untangling_root_dir}/${project_name}/${commit_hash}"

# Untangles a commit from the LLTC4J dataset using $tool_name.
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_and_parse_lltc4j() {
  local vcs_url="$1"
  local commit_hash="$2"
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"
  commit_identifier="${project_name}_${short_commit_hash}"

  local commit_result_dir="${results_dir}/evaluation/${commit_identifier}"
  local project_repository_dir="${results_dir}/repositories/${project_name}"
  local untangling_output_dir="$untangling_tool_output_dir/$commit_identifier"

  local untangling_export_file="${commit_result_dir}/${tool_name}.csv"
  local log_file="${logs_dir}/${commit_identifier}_${tool_name}.log"
  local ground_truth_file="${commit_result_dir}/truth.csv"

  rm -f "$log_file" # Remove previous log file.

  mkdir -p "$untangling_output_dir"

  # TODO: Check that the ground truth exists for all tools. We can't get results without it even if the untangling succeeds.

  # TODO: Only do that if we need to untangle.
  # Copy the repository to a temporary directory to enable parallelization.
  local tmp_repository_dir
  tmp_repository_dir="$(mktemp -d)"
  cp -r "$project_repository_dir"/. "$tmp_repository_dir"

  # Checkout the commit to untangle.
  cd "$tmp_repository_dir" >> "$log_file" 2>&1 || exit 1
  if ! git -c advice.detachedHead=false checkout "$commit_hash" >> "$log_file" 2>&1; then
    status_string="CHECKOUT_FAIL"
  fi
  cd - >> "$log_file" 2>&1 || exit 1

  # Clean repo if flag $REMOVE_NON_CODE_CHANGES is set to true.
  if [ "$REMOVE_NON_CODE_CHANGES" = true ] ; then
    echo "Remove non-code changes $tmp_repository_dir" >> "$log_file" 2>&1

    base_dir=$(pwd)

    cd "$tmp_repository_dir" >> "$log_file" 2>&1 || exit 1

    # Resets the current branch up to this commit.
    git reset -q --hard "$commit_hash" >> "$log_file" 2>&1

    # Remove the non-code changes.
    "$SCRIPT_DIR/clean_lltc4j_repo.sh" >> "$log_file" 2>&1

    # Update the commit hash to the cleaned commit to pass to untangling tools.
    # $tmp_repository_dir is now the cleaned repository.
    revision_clean_fixed=$(git rev-parse HEAD)
    commit_hash="$revision_clean_fixed"

    cd "$base_dir"
  fi

  START="$(date +%s.%N)"

  # TODO: Refactoring into a function so it can return early. The status code can be
  #       determined by the function's return value.
  if [ "$status_string" != "CHECKOUT_FAIL" ]; then

    # Check if the untangling results alreay exist for this commit.
    # If it does, then the untangling result exists and we can skip the untangling process.
    # Otherwise, we need to untangle the commit.
    if [ -f "$untangling_export_file" ]; then
      status_string="CACHED"
    elif has_untangling_output "$untangling_output_dir" "$project_name" "$commit_hash" || untangle_commit "$tmp_repository_dir" "$ground_truth_file" "$commit_hash" "$commit_identifier" "$untangling_output_dir" >> "$log_file" 2>&1; then
      status_string="UNTANGLING_SUCCESS"
    else
      status_string="UNTANGLING_FAIL"
    fi

    # If the untangling tool produced an output, then export it to the CSV format.
    if [ "$status_string" == "UNTANGLING_SUCCESS" ]; then
      if export_untangling_output "$untangling_output_dir" "$untangling_export_file" "$(basename "$tmp_repository_dir")" "$commit_hash" >> "$log_file" 2>&1; then
        status_string="OK"
      else
        status_string="EXPORT_FAIL"
      fi
    fi
  fi

#  rm -rf "$tmp_repository_dir"

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %-20s (time: %.0fs) [%s]\n" "${commit_identifier}" "${status_string}" "${ELAPSED}" "${log_file}"
}

export -f untangle_and_parse_lltc4j

START_TIME=$(date +%s)
tail -n+2 "$commits_file" | parallel --colsep "," untangle_and_parse_lltc4j {}
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
ELAPSED_TIME_FORMATTED=$(date -u -d @"${ELAPSED_TIME}" +"%H:%M:%S")

echo "" >&2
echo "Untangling completed with tool '${tool_name}'." >&2
echo "Total elapsed time: ${ELAPSED_TIME_FORMATTED}." >&2
