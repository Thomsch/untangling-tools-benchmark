#!/bin/bash
# Run the evaluation pipeline end-to-end on 5 bug files: Closure_78, Closure_98, CSV_8, Jsoup_24, Lang_63.
# The decomposition and untangling results are stored in the /e2e folder. 
# The script calls evaluate.sh on the 5 bugs and writes to 2 output files: `decompositions.csv` and `metrics.csv`.
# These 2 aggregated files are expected to be identical to the corresponding goal files.

set -o errexit
set -o nounset
set -o pipefail

if [[ $# -ne 0 ]] ; then
    echo 'usage: ./test/e2e.sh'
    exit 1
fi


# Don't hard code file names
bugs_file="data/d4j-5-bugs.csv" # Path to the file containing the bugs to untangle and evaluate.
out_dir="test/e2e" # Path to the directory where the results are stored and repositories checked out.

metric_goal="${out_dir}/metrics_goal.csv"
decompositions_goal="${out_dir}/decompositions_goal.csv"


# Run the 5_bug example and write output files to /e2e
./evaluate_all.sh "$bugs_file" "$out_dir"

metrics_results="${out_dir}/metrics.csv"
decompositions_results="${out_dir}/decompositions.csv"

# Diff the aggregated metrics file with the goal file
if ! diff -u "$metric_goal" "$metrics_results"; then
    echo "Warning: The metrics computed are different."
    exit 1
else 
    echo "The metrics are identical."
fi

# Diff the aggregated Rand Index scores file with the goal file
if ! diff -u "$decompositions_goal" "$decompositions_results"; then
    echo "Warning: The Rand Index scores computed are different."
    exit 1
else 
    echo "The Rand Index scores are identical."
fi