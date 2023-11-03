# Bash script that implements the tool_file interface for the LLTC4J dataset.

# Check that the environment variables are set for this tool.
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

# Untangles a commit from the LLTC4J dataset using $tool_name.
#
# Arguments:
# - $1: The directory containing the repository for the project.
# - $2: The ground truth file for the commit (ignored by this implementation).
# - $3: The commit hash to untangle (ignored by this implementation).
# - $4: The output directory where the untangling results will be stored.
untangle_commit() {
  local ground_truth_file="$2"
  local untangling_output_dir="$4"

  local untangling_result_file="${untangling_output_dir}/untangling.csv"

  if ! [ -f "$ground_truth_file" ]; then
    echo "Ground truth file not found: ${ground_truth_file}"
    return 1
  fi

  python3 src/python/main/filename_untangling.py "${ground_truth_file}" "${untangling_result_file}"
  return $?
}

# Exports the untangling results to a CSV file.
#
# Arguments:
# - $1: The directory where the untangling results are stored.
# - $2: The CSV file where the untangling results will be exported.
export_untangling_output() {
  local untangling_output_dir="$1"
  local untangling_export_file="$2"

  local untangling_result_file="${untangling_output_dir}/untangling.csv"
  cp "$untangling_result_file" "$untangling_export_file"
}