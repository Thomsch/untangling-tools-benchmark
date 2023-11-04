# Check that the environment variables are set for Flexeme.
check_environment() {
  if [ -z "${JAVAC_TRACES_DIR:-}" ]; then
    echo "Please set the JAVAC_TRACES_DIR environment variable to the directory containing the javac traces."
    echo "See the script try-compiling.sh for more information."
    exit 1
  fi
}

# Check if the untangling tool has already been run on the commit.
#
# Arguments:
# - $1: The directory where the untangling results are stored.
# - $2: The project name (unused in this implementation).
# - $3: The commit hash (unused in this implementation).
has_untangling_output() {
  local untangling_output_dir="$1"

  # TODO: This path is used several time in this file. Create a function to dynamically retrieve it.
  local flexeme_untangling_graph="${untangling_output_dir}/flexeme.dot"
  [ -f "$flexeme_untangling_graph" ]
}

# Untangles a commit from the LLTC4J dataset using Flexeme.
#
# Arguments:
# - $1: The directory containing the repository for the project.
# - $2: The ground truth file for the commit (ignored by this implementation).
# - $3: The commit hash to untangle.
# - $4: The commit identifier.
# - $5: The output directory where the untangling results will be stored.
untangle_commit() {
  local repository_dir="$1"
  local ground_truth_file="$2"
  local commit_hash="$3"
  local commit_identifier="$4"
  local untangling_output_dir="$5"

  # TODO: This path is used several time in this file. Create a function to dynamically retrieve it.
  local flexeme_untangling_graph="${untangling_output_dir}/flexeme.dot"

  # If the ground truth is missing, skip this commit.
  if ! [ -f "$ground_truth_file" ]; then
    echo "Ground truth file not found: ${ground_truth_file}"
    return 1
  fi

  local javac_traces_file="${JAVAC_TRACES_DIR}/${commit_identifier}/dljc-logs/javac.json"
  if ! [ -f "$javac_traces_file" ]; then
    echo "Missing javac traces for ${commit_identifier}"
    return 1
  fi

  # Retrieve the sourcepath and classpath from the javac traces.
  # TODO: $SCRIPT_DIR is defined in untangle_lltc4j_commits.sh. It assumes this
  #       file is in the same repository.
  sourcepath=$(python3 "$SCRIPT_DIR/../../../python/main/retrieve_javac_compilation_parameter.py" -p sourcepath -j "$javac_traces_file")
  classpath=$(python3 "$SCRIPT_DIR/../../../python/main/retrieve_javac_compilation_parameter.py" -p classpath -j "$javac_traces_file")

  echo "Sourcepath: $sourcepath"
  echo "Classpath: $classpath"

  export PYTHONHASHSEED=0 # Set a seed to ensure reproducibility.

  # TODO: Don't assume that the script is called from the root directory.
  ./src/bash/main/untangle_flexeme.sh "$repository_dir" "$commit_hash" "$sourcepath" "$classpath" "${flexeme_untangling_graph}"
}

# Exports the untangling results to a CSV file.
#
# Arguments:
# - $1: The directory where the untangling results are stored.
# - $2: The CSV file where the untangling results will be exported.
# - $3: The project name (unused in this implementation).
# - $4: The commit hash (unused in this implementation).
export_untangling_output() {
  local untangling_output_dir="$1"
  local untangling_export_file="$2"

  # TODO: This path is used several time in this file. Create a function to dynamically retrieve it.
  local flexeme_untangling_graph="${untangling_output_dir}/flexeme.dot"
  python3 src/python/main/flexeme_results_to_csv.py "$flexeme_untangling_graph" "$untangling_export_file"
}
