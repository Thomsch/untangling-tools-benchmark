#!/bin/bash
# Run the evaluation pipeline end-to-end on 5 bug files: Closure_78, Closure_98, CSV_8, Jsoup_24, Lang_63.
# The decomposition and untangling results are stored in the /e2e folder. 
# The script calls evaluate.sh on the 5 bugs and writes to 2 output files: `decompositions.csv` and `metrics.csv`.
# These 2 aggregated files are expected to be identical to the corresponding goal files.

set -o errexit
set -o nounset
set -o pipefail

if [ $# -ne 0 ] ; then
    echo 'usage: ./src/python/test/e2e.sh'
    exit 1
fi

export PYTHONHASHSEED=0         # Make Flexeme deterministic

bugs_file="data/d4j-5-bugs.csv" # The file containing the bugs to untangle.
out_dir="src/python/test/e2e" # The directory where the results are stored and repositories checked out.

metrics_goal="${out_dir}/metrics_goal.csv"
decomposition_scores_goal="${out_dir}/decomposition_scores_goal.csv"


# Run the 5_bug example and write output files to /e2e
./compute_metrics.sh "$bugs_file" "$out_dir"
./generate_ground_truth.sh "$bugs_file" "$out_dir"
./decompose.sh "$bugs_file" "$out_dir"
./score.sh "$bugs_file" "$out_dir"

metrics_results="${out_dir}/metrics.csv"
decomposition_scores_results="${out_dir}/decomposition_scores.csv"

# Diff the aggregated metrics file with the goal file
if ! diff -u "$metrics_goal" "$metrics_results"; then
    echo "Error: The metrics computed are different."
    exit 1
fi

# Diff the aggregated Rand Index scores file with the goal file
if ! diff -u "$decomposition_scores_goal" "$decomposition_scores_results"; then
    echo "Error: The Rand Index scores computed are different."
    exit 1
fi
