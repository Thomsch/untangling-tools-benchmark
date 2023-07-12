#!/bin/bash
# Run the evaluation pipeline end-to-end on the bugs in file "data/d4j-5-bugs.csv".
# The decomposition and untangling results are stored in the /e2e folder. 
# The script calls evaluate.sh on the 5 bugs and writes to 2 output files: `rand_index_scores.csv` and `metrics.csv`.
# These 2 aggregated files are expected to be identical to the corresponding goal files.

set -o errexit
set -o nounset
set -o pipefail

if [ $# -ne 0 ] ; then
    echo 'usage: ./src/python/test/e2e.sh'
    exit 1
fi

export PYTHONHASHSEED=0         # Make test deterministic

bugs_file="data/d4j-5-bugs.csv" # Path to the file containing the bugs to untangle and evaluate.
out_dir="src/python/test/e2e" # Path to the directory where the results are stored and repositories checked out.

metrics_goal="${out_dir}/metrics_goal.csv"
rand_index_scores_goal="${out_dir}/rand_index_scores_goal.csv"

# Run the 5_bug example and write output files to /e2e
./evaluate_all.sh "$bugs_file" "$out_dir"

metrics_results="${out_dir}/metrics.csv"
rand_index_scores_results="${out_dir}/rand_index_scores.csv"

# Diff the aggregated metrics file with the goal file
if ! diff -u "$metrics_goal" "$metrics_results"; then
    echo "Error: The metrics computed are different."
    exit 1
fi

# Diff the aggregated Rand Index scores file with the goal file
if ! diff -u "$rand_index_scores_goal" "$rand_index_scores_results"; then
    echo "Error: The Rand Index scores computed are different."
    exit 1
fi