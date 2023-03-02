#!/bin/bash

if [[ $# -ne 2 ]] ; then
    echo 'usage: evaluate_all.sh <bugs_file> <out_dir>'
    exit 1
fi

bugs_file=$1 # Path to the file containing the bugs to untangle and evaluate.
out_dir=$2 # Path to the directory where the results are stored and repositories checked out.

results="${out_dir}/results" # Contains the results for each commit.
out_file="${out_dir}/decompositions.csv" # Aggregated results.
workdir="${out_dir}/repositories"
metrics_dir="${out_dir}/metrics"
evaluation_dir="${out_dir}/evaluation"
logs_dir="${out_dir}/logs"

mkdir -p "$results"
mkdir -p "$workdir"
mkdir -p "$metrics_dir"
mkdir -p "$logs_dir"

if ! [[ -f "$bugs_file" ]]; then
    echo "File ${bugs_file} not found. Exiting."
    exit 1
fi

# TODO: Parallelize
echo "Logs stored in ${logs_dir}/<project>_<bud_id>.log"
echo ""

error_counter=0
while IFS=, read -r project vid
do
    # TODO: Don't regenerate results when they already exist.
    START=$(date +%s.%N)
    ./evaluate.sh "$project" "$vid" "$out_dir" "$workdir" &> "${logs_dir}/${project}_${vid}.log"
    ret_code=$?
    evaluation_status=$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")
    END=$(date +%s.%N)
    DIFF=$(echo "$END - $START" | bc)
    if [ $ret_code -ne 0 ]; then
        error_counter=$((error_counter+1))
    fi
    printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${evaluation_status}" "${DIFF}"

done < "$bugs_file"

echo ""
echo "Evaluation finished with ${error_counter} errors out of $(wc -l < $bugs_file) commits."

cat "${evaluation_dir}"/*/scores.csv > "$out_file"
#find ${results} -name "*.csv" -type f -delete

echo ""
echo "Decomposition scores aggregated and saved in ${out_file}"

metrics_results="${out_dir}/metrics.csv"

cat "${metrics_dir}"/*.csv > "$metrics_results"
# find ${metrics_dir} -name "*.csv" -type f -delete

echo ""
echo "Commit metrics aggregated and saved in ${metrics_results}"
