#!/bin/bash
# Run the evaluation pipeline end-to-end on 5 bug files: Closure_78, Closure_98, CSV_8, Jsoup_24, Lang_63.
# The decomposition and untangling results are stored in the /e2e folder. 
# The script calls evaluate.sh on the 5 bugs and writes to 2 output files: `decompositions.csv` and `metrics.csv`.
# These 2 aggregated files are expected to be identical to the corresponding goal files.

set -o errexit
set -o nounset
set -o pipefail

if [ $# -ne 0 ] ; then
    echo 'usage: ./evaluate_all.sh'
    exit 1
fi

if [ ! -f .env ] ; then
    echo "No .env file found"
    exit 1
fi

export PYTHONHASHSEED=0         # Make Flexeme deterministic

workdir="$(pwd)"
export workdir
export bugs_file="${workdir}/data/d4j-compatible-bugs.csv" # Path to the file containing the bugs to untangle and evaluate.
export out_dir="${workdir}/benchmark-all" # Path to the directory where the results are stored and repositories checked out.

# Run the 5_bug example and write output files to /e2e
./generate_artifacts.sh "$bugs_file" "$out_dir"
./compute_metrics.sh "$bugs_file" "$out_dir"
./generate_ground_truth.sh "$bugs_file" "$out_dir"
./decompose.sh "$bugs_file" "$out_dir"
./score.sh "$bugs_file" "$out_dir"
