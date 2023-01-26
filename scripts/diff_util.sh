#!/bin/bash

# Generates the unified diff in the same format for Git and Svn repositories
diff () {
    local PROJECT=$1
    local VID=$2
    local REVISION=$3

    vcs=$(defects4j query -p "$PROJECT" -q "project.vcs" | awk -v vid="$VID" -F',' '{ if ($1 == vid) { print $2 } }')
    
    if [[ $vcs == "Vcs::Git" ]] ; then
        git --git-dir="tmp/${PROJECT}_${VID}/.git" diff -U0 "$REVISION"^ "$REVISION"
    elif [[ $vcs == "Vcs::Svn" ]]; then
        svn diff -c "$REVISION" "tmp/${PROJECT}_${VID}"  --diff-cmd diff -x "-U 0"
    else
        echo "Error: VCS ${vcs} not supported."
        exit 1
    fi
}