check_environment() {
  # TODO: Refactor these into functions that can be reused in check-environment-lltc4j.sh. Both places need to check the environment.
  if [ -z "${JAVA11_HOME}" ]; then
    echo 'Set JAVA11_HOME environment variable to the Java 11 installation.'
    return 1
  fi

  if [ ! -d "${JAVA11_HOME}" ]; then
    echo "JAVA11_HOME environment variable is not set to an existing directory: $JAVA11_HOME"
    return 1
  fi
}

# Check if the untangling tool has already been run on the commit.
#
# Arguments:
# - $1: The directory where the untangling results are stored.
# - $2: The project name.
# - $3: The commit hash.
has_untangling_output() {
  local untangling_output_dir="$1"
  local project_name="$2"
  local commit_hash="$3"

  # SmartCommit outputs the untangling results in a subfolder named after the repository name and commit hash.
  # so the results will be stored in untangling_output_dir/<project_name>/<commit_hash>.
  [ -f "$untangling_output_dir/$project_name/$commit_hash" ]
}

# Untangles a commit from the LLTC4J dataset using SmartCommit.
#
# Arguments:
# - $1: The directory containing the repository for the project.
# - $2: The ground truth file for the commit (ignored by this implementation).
# - $3: The commit hash to untangle.
# - $4: The output directory where the untangling results will be stored.
untangle_commit() {
  local repository_dir="$1"
  local ground_truth_file="$2"
  local commit_hash="$3"
  local untangling_output_dir="$4"


  "${JAVA11_HOME}/bin/java" -jar lib/smartcommitcore-1.0-all.jar -r "$repository_dir" -c "$commit_hash" -o "${untangling_output_dir}"
}

# Exports the untangling results to a CSV file.
#
# Arguments:
# - $1: The directory where the untangling results are stored.
# - $2: The CSV file where the untangling results will be exported.
# - $3: The project name.
# - $4: The commit hash.
export_untangling_output() {
  local untangling_output_dir="$1"
  local untangling_export_file="$2"
  local project_name="$3"
  local commit_hash="$4"

  local results_dir="${untangling_output_dir}/$project_name/$commit_hash"

  # TODO: Don't assume that the script is called from the root directory.
  python3 src/python/main/smartcommit_results_to_csv.py "${results_dir}" "${untangling_export_file}"
}