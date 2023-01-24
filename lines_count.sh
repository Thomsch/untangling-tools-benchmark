#!/bin/bash

# Count, for each commit, the number of lines in the bug fix and those that are not in the bug fix.

export DEFECTS4J_HOME="/Users/thomas/Workplace/defects4j"

all_commits="out/commits-sample.csv"
out_file="out/lines.csv"

if ! [[ -f "$all_commits" ]]; then
    echo "File ${all_commits} not found. Exiting."
    exit 1
fi

mkdir -p "./tmp" # Create temporary directory

while IFS=, read -r project vid
do
    workdir=./tmp/"$project"_"$vid"
    truth_out="./out/evaluation/${project}/${vid}/truth.csv"
  
    # Checkout defects4j bug
    defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

    # Get fix commit hash
    commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)  

    if [[ -f "$truth_out" ]]; then
        echo -ne 'Calculating ground truth ................................................ SKIP\r'
    else
        mkdir -p "./out/evaluation/${project}/${vid}"
        ./scripts/ground_truth.sh "$project" "$vid" "$workdir" "$truth_out" "$commit"
        ret_code=$?
        evaluation_status=$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")
        echo -ne "Calculating ground truth .................................................. ${evaluation_status}\r"
    fi
    echo -ne '\n'

    # count number of lines and append
    python3 src/count_lines.py "$truth_out" "$project" "$vid" >> $out_file
    
    # delete workdir
done < $all_commits