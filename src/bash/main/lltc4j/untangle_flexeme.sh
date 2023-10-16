#!/bin/bash
# Untangle with SmartCommit and Flexeme on a list of LLTC4J bugs.
# Arguments:
# - $1: The file containing the commits to untangle.
# - $2: The root directory where the sourcepath and classpath results from '/try-compiling.sh' are stored.
# - $3: The root directory where the ground truth results are stored.

# The decomposition results are written to decomposition/smartcommit/<commit>/ and ~/decomposition/<commit>/flexeme/ subfolder.
# - flexeme/flexeme.dot: The PDG (untangling graph) generated by Flexeme
# - flexeme/time.csv: Run time spent by Flexeme
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time spent by SmartCommit

set -o nounset    # Exit if script tries to use an uninitialized variable
# set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 3 ] ; then
    echo "usage: $0 <commits_file> <javac_traces_dir> <results_dir>"
    exit 1
fi

export commits_file="$1" # The file containing the commits to untangle.
export javac_traces_dir="$2" # The directory where the javac traces are stored.
export results_dir="$3" # The directory where the results are stored and repositories checked out.

if ! [ -f "$commits_file" ]; then
    echo "$0: file ${commits_file} not found. Exiting."
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

set -o allexport
. ./check-environment-lltc4j.sh
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

# Untangles a commit from the LLTC4J dataset using Flexeme.
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_with_tools(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"

  local log_file
  log_file="${logs_dir}/${project_name}_${short_commit_hash}_flexeme.log"

  START="$(date +%s.%N)"

  # If the ground truth is missing, skip this commit.
  if ! [ -f "${results_dir}/evaluation/${project_name}_${short_commit_hash}/truth.csv" ]; then
    untangling_status_string="MISSING_GROUND_TRUTH"
  fi

  javac_traces_file="${javac_traces_dir}/${project_name}_${short_commit_hash}/dljc-logs/javac.json"

  if ! [ -f "$javac_traces_file" ]; then
    untangling_status_string="MISSING_JAVAC_TRACES"
    sourcepath=""
    classpath=""
  else
    # Retrieve the sourcepath and classpath from the javac traces.
    sourcepath=$(python3 "$SCRIPT_DIR/../../../python/main/retrieve_javac_compilation_parameters.py" -p sourcepath -s "$javac_traces_file")
    classpath=$(python3 "$SCRIPT_DIR/../../../python/main/retrieve_javac_compilation_parameters.py" -p classpath -s "$javac_traces_file")
  fi

  # If the untangling status is still empty, untangle the commit.
  if [ -z "$untangling_status_string" ]; then
    ./src/bash/main/lltc4j/untangle_flexeme_commit.sh "$vcs_url" "$commit_hash" "$results_dir" "$sourcepath" "$classpath" > "${log_file}" 2>&1
    ret_code=$?
    if [ $ret_code -eq 0 ]; then
      untangling_status_string="OK"
    elif [ $ret_code -eq 5 ]; then
      untangling_status_string="UNTANGLING_FAIL"
    elif [ $ret_code -eq 6 ]; then
      untangling_status_string="PARSING_FAIL"
    else
      untangling_status_string="FAIL"
    fi
  fi
  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%-20s %-20s (time: %.0fs) [%s]\n" "${project_name}_${short_commit_hash}" "${untangling_status_string}" "${ELAPSED}" "${log_file}"
}

export -f get_project_name_from_url
export -f untangle_with_tools

tail -n+2 "$commits_file" | parallel --colsep "," untangle_with_tools {}

echo "Untangling completed."
