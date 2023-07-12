#!/bin/bash
# Generates the ground truth using the original fix and the minimized version of the D4J bug.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path to the checked out project repository
# - $4: The path where to output the ground truth results
#
# Writes the ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
# - CSV header: {file, source, target, group}
#     - file: The relative file path from the project root for a change
#     - source: The line number of the change if the change is a deletion
#     - target: The line number of the change if the change is an addition
#     - group: 'fix' if the change is a fix, 'other' if the change is a non bug-fixing change

#set -o errexit    # Exit immediately if a command exits with a non-zero status
#set -o nounset    # Exit if script tries to use an uninitialized variable
#set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

if [ $# -ne 2 ] ; then
    echo 'usage: ./ground_truth.sh <project repository> <truth file>'
    echo 'example: ./ground_truth.sh path/to/Lang_1/ evaluation_path/truth.csv'
    exit 1
fi

repository=$1
truth_csv=$2

python3 src/python/main/ground_truth.py "$repository" "$truth_csv"
