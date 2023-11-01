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

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 3 ] ; then
    echo "usage: $0 <commits_file> <results_dir> <tool_name>"
    exit 1
fi

export commits_file="$1"
export results_dir="$2"
export tool_name="$3"

if ! [ -f "$commits_file" ]; then
    echo "$0: commit file ${commits_file} not found. Exiting."
    exit 1
fi

if ! [ -d "$results_dir" ]; then
    echo "$0: directory ${results_dir} not found. Exiting."
    echo "Please generate the ground truth first."
    exit 1
fi

export FLEXEME_TOOL="flexeme"
export SMARTCOMMIT_TOOL="smartcommit"
export FILE_TOOL="file"
ALLOWED_TOOLS=("$FLEXEME_TOOL" "$SMARTCOMMIT_TOOL" "$FILE_TOOL")

if [[ ! " ${ALLOWED_TOOLS[*]} " == *" ${tool_name} "* ]]; then
    formatted_tools=$(printf "'%s', " "${ALLOWED_TOOLS[@]}")
    formatted_tools="${formatted_tools%, }" # Remove the trailing comma and space.
    echo "Invalid untangling tool: '$tool_name'."
    echo "Allowed tools are: $formatted_tools"
    exit 1
fi

# Prepare the environment for each tool.
if [ "$tool_name" == "$FLEXEME_TOOL" ]; then

  # Check for JAVAC Traces environment variable.
  if [ -z "${JAVAC_TRACES_DIR:-}" ]; then
    echo "Please set the JAVAC_TRACES_DIR environment variable to the directory containing the Javac traces."
    echo "See the script try-compiling.sh for more information."
    exit 1
  fi

  export PYTHONHASHSEED=0
  export workdir="${results_dir}/repositories"
  export logs_dir="${results_dir}/logs"

  mkdir -p "$workdir"
  mkdir -p "$logs_dir"

elif [ "$tool_name" == "$SMARTCOMMIT_TOOL" ]; then

  java_version="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)"
  if [ "$java_version" != "1.8" ] ; then
    echo "$0: please use Java 8 instead of ${java_version}"
    exit 1
  fi

elif [ "$tool_name" == "$FILE_TOOL" ]; then

  export workdir="${results_dir}/repositories"
  export logs_dir="${results_dir}/logs"

  mkdir -p "$workdir"
  mkdir -p "$logs_dir"

fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPT_DIR/check-environment-lltc4j.sh"
. "$SCRIPT_DIR/lltc4j_util.sh"
set +o allexport

untangle_and_parse_lltc4j() {
  if [ "$tool_name" == "$FLEXEME_TOOL" ]; then
    untangle_flexeme "$1" "$2"
  elif [ "$tool_name" == "$SMARTCOMMIT_TOOL" ]; then
    untangle_smartcommit "$1" "$2"
  elif [ "$tool_name" == "$FILE_TOOL" ]; then
    untangle_file "$1" "$2"
  else
    echo "Invalid untangling tool: '$tool_name'."
  fi
}

export -f untangle_and_parse_lltc4j

tail -n+2 "$commits_file" | parallel --colsep "," untangle_and_parse_lltc4j {}

echo "Untangling completed."
