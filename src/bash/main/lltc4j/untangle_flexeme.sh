#!/bin/bash
# Untangle with Flexeme on a list of LLTC4J commits.
# Arguments:
# - $1: The file containing the commits to untangle.
# - $2: The directory where the sourcepath and classpath results from 'try-compiling.sh' are stored.
# - $3: The results directory where the ground truth results are stored.

# The decomposition results are written to $results_dir/evaluation/<commit>/.
# - flexeme.csv: The untangling results in CSV format.
# - flexeme_time.csv: Time spent to untangle the commit.


set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 3 ] ; then
    echo "usage: $0 <commits_file> <javac_traces_dir> <results_dir>"
    exit 1
fi

export commits_file="$1"
export javac_traces_dir="$2"
export results_dir="$3"

if ! [ -f "$commits_file" ]; then
    echo "$0: commit file ${commits_file} not found. Exiting."
    exit 1
fi

if ! [ -d "$javac_traces_dir" ]; then
    echo "$0: directory ${javac_traces_dir} not found. Exiting."
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

tail -n+2 "$commits_file" | parallel --colsep "," untangle_flexeme {}

echo "Untangling completed."
