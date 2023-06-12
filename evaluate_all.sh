#!/bin/bash
# Run the untangling tools on a list of Defects4J bugs by calling ./evaluate.sh.
# - $1: Path to the file containing the bugs to untangle and evaluate.
# - $2: Path to the directory where the results are stored and repositories checked out.
# The output of evaluate.sh for each bug file is reported individually in 5 folders: /decompositions, /evaluation, /logs, /metrics, /repositories.
# Returns aggregated scores across all D4J bugs in 2 .csv files, where each row represents one bug in provided list of D4J bugs:
# - decomposition.csv: Decomposition scores, header line: {d4j_project,d4j_bug_id,smartcommit_score,flexeme_score,file_untangling_score}
# - metrics.csv: Commit metrics scores, CSV header: {d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated}

#set -o errexit    # Exit immediately if a command exits with a non-zero status. Disabled because we need to check
# the return code of ./evaluate.sh.
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 2 ]] ; then
    echo 'usage: evaluate_all.sh <bugs_file> <out_dir>'
    exit 1
fi

bugs_file=$1 # Path to the file containing the bugs to untangle and evaluate.
out_dir=$2 # Path to the directory where the results are stored and repositories checked out.

mkdir -p "$out_dir"

out_file="${out_dir}/decompositions.csv" # Aggregated results.
workdir="${out_dir}/repositories"
metrics_dir="${out_dir}/metrics"
evaluation_dir="${out_dir}/evaluation"
logs_dir="${out_dir}/logs"

mkdir -p "$workdir"
mkdir -p "$metrics_dir"
mkdir -p "$logs_dir"

if ! [[ -f "$bugs_file" ]]; then
    echo "File ${bugs_file} not found. Exiting."
    exit 1
fi

# TODO: Parallelize
echo "Logs stored in ${logs_dir}/<project>_<bug_id>.log"
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
    # Must use `bc` because the computation is on floating-point numbers.
    ELAPSED=$(echo "$END - $START" | bc)
    if [ $ret_code -ne 0 ]; then
        error_counter=$((error_counter+1))
    fi
    printf "%-20s %s (%.0fs)\n" "${project}_${vid}" "${evaluation_status}" "${ELAPSED}"

done < "$bugs_file"

echo ""
echo "Evaluation finished with ${error_counter} errors out of $(wc -l < "$bugs_file") commits."

cat "${evaluation_dir}"/*/scores.csv > "$out_file"
echo ""
echo "Decomposition scores aggregated and saved in ${out_file}"

metrics_results="${out_dir}/metrics.csv"
cat "${metrics_dir}"/*.csv > "$metrics_results"
echo ""
echo "Commit metrics aggregated and saved in ${metrics_results}"
