#!/bin/bash
# Run the evaluation piepline end-to-end on 5 bug files: Closure_78, Closure_98, CSV_8, Jsoup_24, Lang_63.
# The decomposition and untangling results are stored in the /e2e folder. 
# The script facilitates the execution of evaluate.sh on a list of bugs, records the evaluation results and timings, and aggregates the scores into two separate output files `decompositions.csv` and `metrics.csv`.
# These 2 aggregated files are expected to be identical to the manually pre-computed Rand Index in goal.csv.

## TODO: Is this a bad implementation? Reasons
    # - Floating point number operations are end result
    # - Future operation (if accounting for tangled lines) can change end result
set -o errexit
set -o nounset
set -o pipefail

if [[ $# -ne 2 ]] ; then
    echo 'usage: e2el.sh <bugs_file> <out_dir>'
    exit 1
fi

bugs_file=$1 # Path to the file containing the bugs to untangle and evaluate.
out_dir=$2 # Path to the directory where the results are stored and repositories checked out.

metric_goal_out="${out_dir}/metrics_goal.csv"
decompositions_goal_out="${out_dir}/decompositions_goal.csv"


# Run the 5_bug example and write output files to /e2e
./evaluate_all.sh "$bugs_file" "$out_dir"

metrics_results="${out_dir}/metrics.csv"
decompositions_results="${out_dir}/decompositions.csv"

# Diff the aggregated metrics file with the goal file
if [[ -f "$metric_goal_out" ]]; then
    diff_metrics=$(diff -u "$metric_goal_out" "$metrics_results")
    # Check if the diff output is empty
    if [ -n "$diff_metrics" ]; then
        echo "Warning: The metrics computed are different."
        echo -e "$diff_metrics"
    fi
    echo "The results are identical."
else 
    echo "Cannot find goal file."
fi

# Diff the aggregated Rand Index scores file with the goal file
if [[ -f "$decompositions_goal_out" ]]; then
    diff_scores=$(diff -u "$decompositions_goal_out" "$decompositions_results")
    # Check if the diff output is empty
    if [ -n "$diff_scores" ]; then
        echo "Warning: The Rand Index computed are different."
        echo -e "$diff_scores"
    fi
    
    echo "The scores are identical."
else 
    echo "Cannot find goal file."
fi