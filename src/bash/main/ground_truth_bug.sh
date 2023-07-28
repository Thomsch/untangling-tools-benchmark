#!/bin/bash
# Generates the ground truth using the original fix and the minimized version of the D4J bug.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path where the results are stored.
# - $4: Path where the repo is checked out
#
# Writes the ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
# - CSV header: {file, source, target, group}
#     - file: The relative file path from the project root for a change
#     - source: The line number of the change if the change is a deletion
#     - target: The line number of the change if the change is an addition
#     - group: 'fix' if the change is a fix, 'other' if the change is a non bug-fixing change

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
if [ -z "$DEFECTS4J_HOME" ] || [ -z "$JAVA11_HOME" ] ; then
  . .env
fi
set +o allexport

if [ $# -ne 4 ] ; then
    echo 'usage: ground_truth_bug.sh <D4J Project> <D4J Bug id> <project repository> <out file>'
    echo 'example: ground_truth_bug.sh Lang 1 path/to/Lang_1/ truth.csv'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

# Initialize related directory for input and output
export evaluation_path="${out_dir}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground truth
mkdir -p "$evaluation_path"

# Calculates the ground truth
echo ""
echo "Calculating ground truth for project $project, bug $vid, repository $repository"

# If D4J bug repository does not exist, checkout the D4J bug to repository and generates 6 artifacts for it.
if [ ! -d "${repository}" ] ; then
  mkdir -p "$repository"
  defects4j checkout -p "$project" -v "$vid"b -w "$repository"
fi

truth_csv="${evaluation_path}/truth.csv"

if [ -f "$truth_csv" ]; then
    echo 'Calculating ground truth ................................................ CACHED'
else
    . ./src/bash/main/d4j_utils.sh
    # Parse the returned result into two variables
    result="$(retrieve_revision_ids "$project" "$vid")"
    read -r revision_buggy revision_fixed <<< "$result"

    if d4j_diff "$project" "$vid" "$revision_buggy" "$revision_fixed" "$repository" | python3 src/python/main/ground_truth.py "$project" "$vid" "$truth_csv"
    then
        echo 'Calculating ground truth .................................................. OK'
    else
        echo 'Calculating ground truth .................................................. FAIL'
    fi
fi
