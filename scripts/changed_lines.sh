#!/bin/bash

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 4 ]] ; then
    echo 'usage: changed_lines.sh <D4J Project> <D4J Bug id> <project repository> <commit id>'
    echo 'example: changed_lines.sh Lang 1 path/to/Lang_1/ e3a4b0c'
    exit 1
fi

project=$1
vid=$2
REPO="$3"
COMMIT="$4"

source ./scripts/diff_util.sh

# Git diff -U0 on top of Vn +  Pipe output to changed_lines.py
d4j_diff "$project" "$vid" "$COMMIT" "$REPO" | python3 src/parse_patch.py
# git --git-dir="$REPO" diff -U0 "$COMMIT"^ "$COMMIT" | python3 src/parse_patch.py
