#!/bin/bash
## TODO: What does this script do?  What are its input and output?

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 3 ]] ; then
    echo 'usage: changed_lines.sh <D4J Project> <D4J Bug id> <project repository>'
    echo 'example: changed_lines.sh Lang 1 path/to/Lang_1/'
    exit 1
fi

PROJECT=$1
VID=$2
REPO="$3"

source ./scripts/d4j_utils.sh

# Parse the returned result into two variables
result=$(retrieve_revision_ids "$PROJECT" "$VID")
read -r revision_buggy revision_fixed <<< "$result"

d4j_diff "$PROJECT" "$VID" "$revision_buggy" "$revision_fixed" "$REPO" | python3 src/parse_patch.py
