#!/bin/bash
# Generates the unified diff in the same format for Git and Svn repositories for a defects4j commit.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

d4j_diff () {

    if [[ $# -ne 5 ]] ; then
      echo 'usage: d4j_diff <D4J Project> <D4J Bug id> <Revision Before> <Revision After> <Project Repository>'
      echo 'example: d4j_diff Lang 1 abc def path/to/Lang_1/'
      exit 1
    fi

    local PROJECT=$1
    local VID=$2
    local REVISION_BUGGY=$3
    local REVISION_FIXED=$4
    local REPO_DIR=$5

    vcs=$(defects4j query -p "$PROJECT" -q "project.vcs" | awk -v vid="$VID" -F',' '{ if ($1 == vid) { print $2 } }')
    
    if [[ $vcs == "Vcs::Git" ]] ; then
        git --git-dir="${REPO_DIR}/.git" diff -U0 "$REVISION_BUGGY" "$REVISION_FIXED"
    elif [[ $vcs == "Vcs::Svn" ]]; then
        svn diff -c --old"${REVISION_BUGGY}" --new="${REVISION_FIXED}" "${REPO_DIR}"  --diff-cmd diff -x "-U 0"
    else
        echo "Error: VCS ${vcs} not supported."
        return 1
    fi
}