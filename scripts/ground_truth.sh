#!/bin/bash
# Generates the ground truth using the original fix and the minimized version of the D4J bug.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path to the checked out project repository
# - $4: The path where to output the results
# - $5: The commit id to use
# - $6: Whether to exclude non-code changes from the ground truth

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 6 ]] ; then
    echo 'usage: ground_truth <D4J Project> <D4J Bug id> <project repository> <out file> <commit id> <exclude_non_code_changes>'
    echo 'example: ground_truth Lang 1 path/to/Lang_1/ truth.csv e3a4b0c False'
    exit 1
fi

project=$1
vid=$2
repository=$3
truth_out=$4
commit=$5
exclude_non_code_changes=$6

source ./scripts/diff_util.sh
d4j_diff "$project" "$vid" "$commit" "$repository" | python3 src/ground_truth.py "$project" "$vid" "$truth_out" "$exclude_non_code_changes"