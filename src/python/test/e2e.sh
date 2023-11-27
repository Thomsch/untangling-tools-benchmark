#!/bin/bash
# Run the evaluation pipeline end-to-end on 5 bug files: Closure_78, Closure_98, CSV_8, Jsoup_24, Lang_63.
# The decomposition and untangling results are stored in the e2e/ folder.
# The script calls evaluate.sh on the 5 bugs and writes to 2 output files: `decompositions.csv` and `metrics.csv`.
# These 2 aggregated files are expected to be identical to the corresponding goal files.

set -o errexit
set -o nounset
set -o pipefail

if [ $# -ne 0 ] ; then
    echo 'usage: ./src/python/test/e2e.sh'
    exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/../../../check-environment.sh
set +o allexport

echo "Using untangling-tools-benchmark commit: $(git show --oneline | head -1)"

export PYTHONHASHSEED=0         # Make Flexeme deterministic

workdir="$(pwd)"
export workdir
export bugs_file="${workdir}/data/d4j-5-bugs.csv" # Path to the file containing the bugs to untangle and evaluate.

# Run the evaluation pipeline end to end on sample D4J bugs and compare the results with the expected results.
#
# Arguments:
# - $1: The folder where the results are stored and repositories checked out. This folder should also contain the expected scores and metrics.
function run_e2e() {
  local out_dir=$1
  local metrics_expected_file="${out_dir}/metrics_expected.csv"
  local untangling_scores_expected_file="${out_dir}/untangling_scores_expected.csv"

  # Run the 5_bug example and write output files to e2e/
  echo "about to run compute_metrics.sh"
  ./compute_metrics.sh "$bugs_file" "$out_dir"
  echo "compute_metrics.sh: done"
  ./generate_ground_truth.sh "$bugs_file" "$out_dir"
  echo "generate_ground_truth.sh: done"
  ./decompose.sh "$bugs_file" "$out_dir"
  echo "decompose.sh: done"
  ./score.sh "$bugs_file" "$out_dir"
  echo "score.sh: done"

  metrics_results="${out_dir}/metrics.csv"
  untangling_scores_results="${out_dir}/decomposition_scores.csv"

  # Diff the aggregated metrics file with the goal file
  if ! diff -u "$metrics_expected_file" "$metrics_results"; then
      echo "$0: error: The metrics computed are different."
      exit 1
  fi

  # Diff the aggregated Rand Index scores file with the goal file
  if ! diff -u "$untangling_scores_expected_file" "$untangling_scores_results"; then
      echo "$0: error: The Rand Index scores computed are different."
      exit 1
  fi
}

export out_root_dir="${workdir}/src/python/test/e2e"

# Run on code changes only
echo "$0: Run e2e on code changes only"
export REMOVE_NON_CODE_CHANGES=true
run_e2e "${out_root_dir}/code-changes"

# Run on all changes
echo "$0: Run e2e on all changes"
export REMOVE_NON_CODE_CHANGES=false
run_e2e "${out_root_dir}/all-changes"


