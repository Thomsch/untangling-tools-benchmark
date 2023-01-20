#!/bin/bash

all_commits="out/commits.csv"
sample_out="out/commits-sample.csv"
results="out/results" # Contains the results for each commit.
out_file="out/decompositions.csv" # Aggregated results.

N=10 # Number of commits to sample

mkdir -p $results

if ! [[ -f "$all_commits" ]]; then
    echo "File ${all_commits} not found. Exiting."
    exit 1
fi

if ! [[ -f "$sample_out" ]]; then
    echo "Generating ${N} commit samples (${sample_out})"
    shuf -n $N $all_commits > $sample_out
fi

# TODO: Parallelize
echo "Logs stored in ${results}/<project>_<bud_id>.log"
echo ""

while IFS=, read -r project vid
do
    # TODO: Don't regenerate results when they already exist.
    START=$(date +%s.%N)
    ./evaluate.sh "$project" "$vid" "$results" &> "${results}/${project}_${vid}.log"
    ret_code=$?
    evaluation_status=$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")
    END=$(date +%s.%N)
    DIFF=$(echo "$END - $START" | bc)
    printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${evaluation_status}" "${DIFF}"
    
done < $sample_out

cat ${results}/*.csv > $out_file

echo ""
echo "Decomposition scores aggregated and saved in ${out_file}"
