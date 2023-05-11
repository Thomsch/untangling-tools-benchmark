#!/bin/bash
# Run the untangling tools on a list of Defects4J bugs.

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

workdir="${out_dir}/repositories"
metrics_dir="${out_dir}/metrics"
logs_dir="${out_dir}/logs"

mkdir -p "$workdir"
mkdir -p "$metrics_dir"
mkdir -p "$logs_dir"

if ! [[ -f "$bugs_file" ]]; then
    echo "File ${bugs_file} not found. Exiting."
    exit 1
fi

echo "Logs stored in ${logs_dir}/project_vid_truth.log"
echo ""

error_counter=0
while IFS=, read -r project vid
do
    START=$(date +%s.%N)
    ./generate_ground_truth.sh "$project" "$vid" "$out_dir" "$workdir" &> "${logs_dir}/${project}_${vid}_truth.log"
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
echo "Generation finished with ${error_counter} errors out of $(wc -l < "$bugs_file") commits."