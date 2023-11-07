#!/bin/bash

# Implementation of the untangling tool functions used in untangle_lltc4j_commits.sh for the file name based untangling approach.

# Check that the environment variables are set for the file name based untangling approach.
check_environment() {
  # File-based approach doesn't require any environment variables.
  return 0
}

# Check if the untangling tool has already been run on the commit.
#
# Arguments:
# - $1: The directory where the untangling results are stored.
has_untangling_output() {
  local untangling_output_dir="$1"

  local untangling_result_file="${untangling_output_dir}/untangling.csv"
  [ -f "$untangling_result_file" ]
}

# Untangles a commit from the LLTC4J dataset using a file-based approach.
#
# Arguments:
# - $1: The directory containing the repository for the project.
# - $2: The ground truth file for the commit.
# - $3: The commit hash to untangle.
# - $4: The commit identifier (e.g., commitSHA_projectName. Varies per project).
# - $5: The output directory where the untangling results will be stored.
untangle_commit() {
  local ground_truth_file="$2"
  local untangling_output_dir="$5"

  local untangling_result_file="${untangling_output_dir}/untangling.csv"

  python3 src/python/main/filename_untangling.py "${ground_truth_file}" "${untangling_result_file}"
}

# Converts the untangling output to a CSV file.
#
# Arguments:
# - $1: The directory where the output of the untangling tool is stored.
# - $2: The CSV file where the untangling results will be exported.
# - $3: The project name (unused in this implementation).
# - $4: The commit hash (unused in this implementation).
convert_untangling_output_to_csv() {
  local untangling_output_dir="$1"
  local untangling_export_file="$2"

  local untangling_result_file="${untangling_output_dir}/untangling.csv"
  cp "$untangling_result_file" "$untangling_export_file"
}