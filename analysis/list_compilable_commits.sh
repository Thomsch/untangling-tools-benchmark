#!/bin/bash
#
# Removes compilable commits from the evaluation results.
# A commit is considered uncompilable if there is no javac trace associated with it.
#
# Arguments:
# - $1: File containing a list of commits that were compiled using try-compile.sh.
# - $2: The top-level directory where the javac traces from '/try-compiling.sh' are stored.
#

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 2 ]] ; then
    echo "usage: $0 <commits-file> <javac-traces-dir>"
    exit 1
fi

export commits_file=$1
export javac_traces_dir=$2

if ! [ -f "$commits_file" ]; then
    echo "$0: file ${commits_file} not found. Exiting."
    exit 1
fi

if ! [ -d "$javac_traces_dir" ]; then
    echo "$0: directory ${javac_traces_dir} not found. Exiting."
    exit 1
fi

export SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPT_DIR/../src/bash/main/lltc4j/lltc4j_util.sh"

echo "vcs_url,commit_hash,parent_hash"

find_trace(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local parent_hash="$3" # The parent commit hash.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"

  javac_traces_file="${javac_traces_dir}/${project_name}_${short_commit_hash}/dljc-logs/javac.json"

  if [ -f "$javac_traces_file" ]; then
    printf "%s,%s,%s\n" "$vcs_url" "$commit_hash" "$parent_hash"
  fi
}

export -f find_trace
tail -n+2 "$commits_file" | parallel --colsep "," find_trace {}