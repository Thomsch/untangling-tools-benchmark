#!/bin/bash
# Count, for each commit, the number of lines in the bug fix and those that are not in the bug fix.
# The script calls ground_truth.sh to generate a truth.csv file, then calls count_lines.py to count 'fix' versus 'other' commits.
# - $1: Path where the D4J bug file is stored.
# - $2: Path where the line counting result is checked out
#
# Writes a lines.csv file (with 1 row) to the specified path.
# - CSV header: project,bug_id,fix_lines=number of bug-fixing lines,nonfix_line=number of non bug-fixing lines
#
# If the ground truth cannot be calculated for a commit, the script will tag the commit as 'FAIL' in the output file.
# When the ground truth cannot be calculated for a commit, the script will tag the commit as 'FAIL' in the output file
# and proceed to the next commit. This avoid having to restart the script everytime there is an issue with a commit and
# allows users to fix problematic commits while the rest of the ground truth is being calculated.
#
# When the problematic commits are fixed, the script can be re-run to calculate the ground truth for the commits that
# failed. The script will not re-calculate the ground truth for a commit if the ground truth has already been calculated.
#
set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

if [[ $# -ne 2 ]] ; then
    echo 'usage: lines_count.sh <commit_file> <out_file>'
    echo 'example: lines_count.sh data/d4j-bugs.csv lines.csv'
    exit 1
fi

all_commits_file=$1
out_file=$2

if ! [[ -f "$all_commits_file" ]]; then
    echo "File ${all_commits_file} not found. Exiting."
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
    commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)  

    if [[ -f "$truth_csv" ]]; then
        echo -ne 'Calculating ground truth ................................................ CACHED\n'
    else
        mkdir -p "./out/evaluation/${project}/${vid}"
        ./scripts/ground_truth.sh "$project" "$vid" "$workdir" "$truth_csv" "$commit"
        ret_code=$?
        # TODO: Use an if statement to avoid spawning a new subshell.
        evaluation_status_string=$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")
        echo -ne "Calculating ground truth .................................................. ${evaluation_status_string}\n"
    fi

    # count number of lines and append
    python3 src/count_lines.py "$truth_csv" "$project" "$vid" >> "$out_file"
done < "$all_commits_file"
