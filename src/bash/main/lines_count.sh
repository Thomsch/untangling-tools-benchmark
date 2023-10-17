#!/bin/bash
#

# Counts the number of bug-fixing lines and non-bug-fixing lines from
# the ground truth.
# This implementation does not account for tangled lines. A tangled
# line is counted as a non-bug-fixing line.
# The script calls ground_truth.sh to generate a truth.csv file, then
# calls count_lines.py to count 'fix' versus 'other' commits.
# Arguments:
# - $1: The D4J bug file.
# - $2: File where the line counting result is written.
#
# Writes a lines.csv file (with 1 row) to the specified path.
# - CSV header: project,bug_id,fix_lines=number of bug-fixing lines,nonfix_line=number of non bug-fixing lines
#
# If the ground truth cannot be calculated for a commit, the script
# will tag the commit as 'FAIL' in the output file.  When the ground
# truth cannot be calculated for a commit, the script will tag the
# commit as 'FAIL' in the output file and proceed to the next
# commit. This avoid having to restart the script everytime there is
# an issue with a commit and allows users to fix problematic commits
# while the rest of the ground truth is being calculated.
#
# When the problematic commits are fixed, the script can be re-run to
# calculate the ground truth for the commits that failed. The script
# will not re-calculate the ground truth for a commit if the ground
# truth has already been calculated.
#
set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/../../../check-environment.sh
set +o allexport

if [ $# -ne 2 ] ; then
    echo 'usage: lines_count.sh <commit_file> <out_file>'
    echo 'example: lines_count.sh data/d4j-bugs.csv lines.csv'
    exit 1
fi

all_commits_file="$1"
out_file="$2"

if ! [ -f "$all_commits_file" ]; then
    echo "$0: file ${all_commits_file} not found. Exiting."
    exit 1
fi

mkdir -p ".tmp" # Create temporary directory

echo "project,bug_id,fix_lines,nonfix_lines" > "$out_file"

while IFS=, read -r project vid
do
    workdir=./tmp/"$project"_"$vid"
    truth_csv="./out/evaluation/${project}/${vid}/truth.csv"
  
    # Checkout Defects4J bug
    defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

    # Get fix commit hash
    commit="$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)"

    if [ -f "$truth_csv" ]; then
        echo 'Calculating ground truth ............................................. CACHED'
    else
        mkdir -p "./out/evaluation/${project}/${vid}"
        if ./src/bash/main/ground_truth.sh "$project" "$vid" "$workdir" "$truth_csv" "$commit"
        then
            echo "Calculating ground truth ............................................. OK"
        else
            echo "Calculating ground truth ............................................. FAIL"
        fi
    fi

    # count number of lines and append
    python3 src/python/main/count_lines.py "$truth_csv" "$project" "$vid" >> "$out_file"
done < "$all_commits_file"
