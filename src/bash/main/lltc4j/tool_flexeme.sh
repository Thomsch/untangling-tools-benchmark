#!/bin/bash

# Implementation of the untangling tool functions used in untangle_lltc4j_commits.sh for Flexeme.

# Check that the environment variables are set for Flexeme.
check_environment() {
  if [ -z "${JAVAC_TRACES_DIR:-}" ]; then
    echo "Please set the JAVAC_TRACES_DIR environment variable to the directory containing the javac traces."
    echo "See the script generate-javac-traces.sh for more information."
    exit 1
  fi

  if ! jq --version > /dev/null 2>&1; then
    echo "jq is not installed. Please install it."
    echo "See https://jqlang.github.io/jq/ for more information."
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

  # TODO: This path is used several times in this file. Create a function to dynamically retrieve it.
  local flexeme_graph_file="${untangling_output_dir}/flexeme.dot"
  if [ -f "$flexeme_graph_file" ]; then
    echo "$flexeme_graph_file already exists."
    return 0
  else
    echo "$flexeme_graph_file doesn't exist."
    return 1
  fi
}

# Untangles a commit from the LLTC4J dataset using Flexeme.
#
# Arguments:
# - $1: The directory containing the repository for the project.
# - $2: The ground truth file for the commit (unused in this implementation).
# - $3: The commit hash to untangle.
# - $4: The commit identifier (used only for diagnostic messages in this implementation).
# - $5: The output directory where the untangling results will be stored.
untangle_commit() {
  local repository_dir="$1"
  local commit_hash="$3"
  local commit_identifier="$4"
  local untangling_output_dir="$5"

  # TODO: This path is used several times in this file. Create a function to dynamically retrieve it.
  local flexeme_graph_file="${untangling_output_dir}/flexeme.dot"

  local javac_traces_file="${JAVAC_TRACES_DIR}/${commit_identifier}/dljc-logs/javac.json"
  if ! [ -f "$javac_traces_file" ]; then
    echo "Missing javac traces for ${commit_identifier} in ${javac_traces_file}"
    return 1
  fi

  # Retrieve the sourcepath and classpath from the javac traces.
  # TODO: Check that $SCRIPT_DIR is defined. This script file assumes that it is in the same directory as untangle_lltc4j_commits.sh.
  sourcepath=$(jq --raw-output '[.[] | .javac_switches.sourcepath] | add' "$javac_traces_file")
  classpath=$(jq --raw-output '[.[] | .javac_switches.classpath] | add' "$javac_traces_file")

  echo "Sourcepath: $sourcepath"
  echo "Classpath: $classpath"

  export PYTHONHASHSEED=0 # Set a seed to ensure reproducibility.

  # TODO: Don't assume that the script is called from the root directory.
  ./src/bash/main/untangle_flexeme.sh "$repository_dir" "$commit_hash" "$sourcepath" "$classpath" "${flexeme_graph_file}"
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

  # TODO: This path is used several times in this file. Create a function to dynamically retrieve it.
  local flexeme_graph_file="${untangling_output_dir}/flexeme.dot"
  python3 src/python/main/flexeme_results_to_csv.py "$flexeme_graph_file" "$untangling_export_file"
}
