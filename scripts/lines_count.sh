#!/bin/bash

# Count, for each commit, the number of lines in the bug fix and those that are not in the bug fix.

set -o allexport
source .env
set +o allexport

all_commits="out/commits.csv"
out_file="out/lines.csv"

if ! [[ -f "$all_commits" ]]; then
    echo "File ${all_commits} not found. Exiting."
    exit 1
fi

mkdir -p "./tmp" # Create temporary directory


echo "project,bug_id,fix_lines,other_lines" > $out_file

while IFS=, read -r project vid
do
    workdir=./tmp/"$project"_"$vid"
    truth_out="./out/evaluation/${project}/${vid}/truth.csv"
  
    # Checkout Defects4J bug
    defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

    # Get fix commit hash
    commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)  

    if [[ -f "$truth_out" ]]; then
        echo -ne 'Calculating ground truth ................................................ SKIP\r\n'
    else
        mkdir -p "./out/evaluation/${project}/${vid}"
        ./scripts/ground_truth.sh "$project" "$vid" "$workdir" "$truth_out" "$commit"
        ret_code=$?
        evaluation_status=$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")
        echo -ne "Calculating ground truth .................................................. ${evaluation_status}\r\n"
    fi

    # count number of lines and append
    python3 src/count_lines.py "$truth_out" "$project" "$vid" >> $out_file
    
    # delete workdir
done < $all_commits
