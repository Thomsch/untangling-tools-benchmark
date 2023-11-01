#!/bin/bash
# Untangle with SmartCommit on a list of LLTC4J bugs.
# Arguments:
# - $1: The file containing the commits to untangle.
# - $2: The directory where the results are stored and repositories checked out.

# The output of Smartcommit is stored in $out_dir/decomposition/smartcommit/<commit>/.
# The untangling results are stored in $out_dir/evaluation/<commit>/
# - smartcommit.csv: The untangling results in CSV format.
# - smartcommit_time.csv.csv: Time spent to untangle the commit.

set -o nounset    # Exit if script tries to use an uninitialized variable
# set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: untangle_smartcommit.sh <commits_file> <results_dir>'
    exit 1
fi

export commits_file="$1" # The file containing the commits to untangle.
export results_dir="$2" # The directory where the results are stored and repositories checked out.

if ! [ -f "$commits_file" ]; then
    echo "$0: commit file ${commits_file} not found. Exiting."
    exit 1
fi

mkdir -p "$results_dir"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPT_DIR/../../../../check-environment-lltc4j.sh"
set +o allexport

# Defects4J will use whatever is on JAVA_HOME.
# Check that Java is 1.8 for Defects4J.
java_version="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)"
if [ "$java_version" != "1.8" ] ; then
    echo "$0: please use Java 8 instead of ${java_version}"
    exit 1
fi

export workdir="${results_dir}/repositories"
export logs_dir="${results_dir}/logs"

mkdir -p "$workdir"
mkdir -p "$logs_dir"

echo "$0: logs will be stored in ${logs_dir}/<project>_<commit_hash>_untangle.log"
echo ""

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPTDIR/lltc4j_util.sh"

tail -n+2 "$commits_file" | parallel --colsep "," untangle_smartcommit {}
