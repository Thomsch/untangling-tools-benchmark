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

tail -n+2 "$commits_file" | parallel --colsep "," untangle_file_baseline {}

echo "Untangling completed."
