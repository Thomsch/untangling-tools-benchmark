#!/bin/bash
# Untangle with SmartCommit and Flexeme on a list of LLTC4J bugs.
# Arguments:
# - $1: The file containing the commits to untangle.
# - $2: The directory where the results are stored and repositories checked out.

# The decomposition results are written to decomposition/smartcommit/<commit>/ and ~/decomposition/<commit>/flexeme/ subfolder.
# - flexeme/flexeme.dot: The PDG (untangling graph) generated by Flexeme
# - flexeme/time.csv: Run time spent by Flexeme
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time spent by SmartCommit

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
    echo "$0: file ${commits_file} not found. Exiting."
    exit 1
fi

mkdir -p "$results_dir"

set -o allexport
. ./check-environment-lltc4j.sh
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

export PYTHONHASHSEED=0

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPTDIR/lltc4j_util.sh"

# Untangles a commit from the LLTC4J dataset using SmartCommit and Flexeme.
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_with_tools(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"

  START="$(date +%s.%N)"   # Record start time for bug decomposition
  ./src/bash/main/lltc4j/untangle_lltc4j_commit.sh "$vcs_url" "$commit_hash" "$results_dir" > "${logs_dir}/${project_name}_${short_commit_hash}_untangle.log" 2>&1
  ret_code=$?
  untangling_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (time: %.0fs)\n" "${project_name}_${short_commit_hash}" "${untangling_status_string}" "${ELAPSED}"
}

export -f get_project_name_from_url
export -f untangle_with_tools
tail -n+2 "$commits_file" | parallel --colsep "," untangle_with_tools {}