#!/bin/bash

bugs_file=$1 # Path to the file containing the bugs to untangle and evaluate.

out_dir='out'
results="${out_dir}/results" # Contains the results for each commit.
out_file="out/decompositions.csv" # Aggregated results.

mkdir -p $results

if ! [[ -f "$bugs_file" ]]; then
    echo "File ${bugs_file} not found. Exiting."
    exit 1
fi

# TODO: Parallelize
echo "Logs stored in ${results}/<project>_<bud_id>.log"
echo ""

while IFS=, read -r project vid
do
    # TODO: Don't regenerate results when they already exist.
    START=$(date +%s.%N)
    ./evaluate.sh "$project" "$vid" "$out_dir" "tmp" &> "${results}/${project}_${vid}.log"
    ret_code=$?
    evaluation_status=$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")
    END=$(date +%s.%N)
    DIFF=$(echo "$END - $START" | bc)
    printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${evaluation_status}" "${DIFF}"
    
done < "$bugs_file"

cat ${results}/*.csv > $out_file
find ${results} -name "*.csv" -type f -delete

echo ""
echo "Decomposition scores aggregated and saved in ${out_file}"

metrics_dir="out/metrics"
metrics_results="out/metrics.csv"

cat ${metrics_dir}/*.csv > $metrics_results
# find ${metrics_dir} -name "*.csv" -type f -delete

echo ""
echo "Commit metrics aggregated and saved in ${metrics_results}"
