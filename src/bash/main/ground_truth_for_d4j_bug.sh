#!/bin/bash
# Generates the ground truth using the original fix and the minimized version of the D4J bug.
# Arguments:
# - $1: D4J Project name.
# - $2: D4J Bug id.
# - $3: Directory where the results are stored.
# - $4: Directory where the repo is checked out.
#
# Writes the ground truth for the respective D4J bug file in evaluation/<project>_<id>/truth.csv
# - CSV header: {file, source, target, group}
#     - file: The relative file path from the project root for a change
#     - source: The line number of the change if the change is a deletion
#     - target: The line number of the change if the change is an addition
#     - group: 'fix' if the change is a fix, 'other' if the change is a non bug-fixing change

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/../../../check-environment.sh
set +o allexport

if [ $# -ne 4 ] ; then
    echo 'usage: ground_truth_for_d4j_bug.sh <D4J Project> <D4J Bug id> <out file> <project clone>'
    echo 'example: ground_truth_for_d4j_bug.sh Lang 1 path/to/Lang_1/'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

# Path containing the evaluation results. i.e., ground truth
export evaluation_dir="${out_dir}/evaluation/${project}_${vid}"
mkdir -p "$evaluation_dir"

echo ""
echo "Calculating ground truth for project $project, bug $vid, repository $repository"

# If D4J bug repository does not exist, checkout the D4J bug to repository and
# generates 6 artifacts for it.
if [ ! -d "${repository}" ] ; then
  mkdir -p "$repository"
  ./src/bash/main/generate_d4j_artifacts.sh "$project" "$vid" "$repository"
fi

truth_csv="${evaluation_dir}/truth.csv"

if [ -f "$truth_csv" ]; then
    echo 'Calculating ground truth ............................................. CACHED'
else
    if python3 -m src.python.main.ground_truth "$repository" "$truth_csv"
    then
        echo 'Calculating ground truth ............................................. OK'
    else
        echo 'Calculating ground truth ............................................. FAIL'
        exit 1        # Exit with status code 1 to mark this run as FAIL when called in generate_ground_truth.sh
    fi
fi
