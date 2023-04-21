#!/bin/bash
# Retrieves the minimal bug-fixing changes for a Defects4J bug.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 5 ]] ; then
    echo 'usage: ground_truth <D4J Project> <D4J Bug id> <project repository> <out file> <commit id>'
    echo 'example: ground_truth Lang 1 path/to/Lang_1/ truth.csv e3a4b0c'
    exit 1
fi

project=$1
vid=$2
repository=$3
truth_out=$4
commit=$5

./scripts/changed_lines.sh "$project" "$vid" "$repository" "$commit" | python3 src/ground_truth.py "$project" "$vid" "$truth_out"
