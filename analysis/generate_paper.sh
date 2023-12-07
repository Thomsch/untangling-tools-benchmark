#!/bin/bash
#
# Generates the results for the paper automatically.
#
# Arguments:
# - $1: The directory where the untangling evaluation results for D4J are stored.
# - $2: The directory where the untangling evaluation results are LLTC4J stored.
# - $3: The directory of the paper repository.
#

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 3 ]] ; then
    echo "usage: $0 <d4j-results-dir> <lltc4j-results-dir> <paper-repository>"
    echo "example: $0 ~/d4j-evaluation ~/lltc4j-evaluation ~/papers/untangling-tools-evaluation"
    exit 1
fi

export D4J_RESULTS_DIR=$1
export LLTC4J_RESULTS_DIR=$2
export PAPER_REPOSITORY=$3

export SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPT_DIR/../src/bash/main/lltc4j/lltc4j_util.sh"

# Implementation of the script's logic. See script's description for more details.
main() {
  check_directory "$D4J_RESULTS_DIR"
  check_directory "$LLTC4J_RESULTS_DIR"
  check_directory "$PAPER_REPOSITORY"

  D4J_SCORE_FILE="${D4J_RESULTS_DIR}/decomposition_scores.csv"
  LLTC4J_SCORE_FILE="${LLTC4J_RESULTS_DIR}/decomposition_scores.csv"

  check_file "$D4J_SCORE_FILE"
  check_file "$LLTC4J_SCORE_FILE"
  
  #
  # Data
  #
  python analysis/paper/count_missing_results.py "${TMP_DIR}" > "${PAPER_REPOSITORY}/data/missing_decompositions.txt"
  analysis/paper/flexeme_no_changes.sh "${TMP_DIR}" > "${PAPER_REPOSITORY}/data/flexeme_no_changes.txt"
  
  #
  # Untangling performance
  #
  python src/python/main/analysis/print_median_performance.py --d4j "$D4J_SCORE_FILE" --lltc4j "$LLTC4J_SCORE_FILE" > "${PAPER_REPOSITORY}/tables/tool-performance.tex" 2> "${PAPER_REPOSITORY}/lib/tool-performance.tex"

  #
  # Untangling statistics
  #
  python src/python/main/analysis/print_group_counts.py --d4j "$D4J_RESULTS_DIR" --lltc4j "$LLTC4J_RESULTS_DIR" > "${PAPER_REPOSITORY}/tables/group-count.tex"
  python src/python/main/analysis/print_group_sizes.py --d4j "$D4J_RESULTS_DIR" --lltc4j "$LLTC4J_RESULTS_DIR" > "${PAPER_REPOSITORY}/tables/group-size.tex"

  #
  # RQ1
  #
  Rscript analysis/paper/performance_distribution.R "${TMP_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/figures/rq1-performance-distribution.pdf"
  Rscript src/r/main/statistical_analysis_untangling_tool.R "${TMP_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/data/"
  Rscript analysis/paper/compare_models.R "${TMP_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/tables/model-comparison.tex" > "${PAPER_REPOSITORY}"/data/model-comparison.txt

  #
  # RQ2
  #
  Rscript analysis/paper/statistical_analysis_commit_metrics.R "${TMP_DIR}/decomposition_scores.csv" "${TMP_DIR}/metrics.csv" "${PAPER_REPOSITORY}/data"
}

# Copy the results of a dataset to a temporary directory.
copy_dataset() {
  # Temporary directory for intermediate results
  TMP_DIR=$(mktemp -d)
  export TMP_DIR

  # Copy results in a temporary directory to avoid modifying the original results.
  mkdir -p "${TMP_DIR}/evaluation"
  cp -r "${D4J_RESULTS_DIR}/logs" "${TMP_DIR}/logs"
  cp "${D4J_RESULTS_DIR}/metrics.csv" "${TMP_DIR}/metrics.csv"

  export -f copy_commit_results
  tail -n+2 "$COMMITS_FILE" | parallel --colsep "," copy_commit_results {}

  # Generate the aggregated scores for the given commits.
  if ! cat "${TMP_DIR}/evaluation"/*/scores.csv > "${TMP_DIR}/decomposition_scores.csv" ; then
    echo "No \"scores.csv\" files found under ${TMP_DIR}."
    exit 1
  fi
}

# Copy commits that are in the given list.
copy_commit_results(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"

  source_dir="${D4J_RESULTS_DIR}/evaluation/${project_name}_${short_commit_hash}/"

  if [ ! -d "$source_dir" ]; then
    echo "Error: Directory '${source_dir}' not found."
    return 1
  fi

  cp -r "${source_dir}" "${TMP_DIR}/evaluation/"
}

# Check that the given path is an existing directory. Exit otherwise.
check_directory() {
  if [ ! -d "$1" ]; then
    echo "Error: '$1' is not an existing directory. Exiting."
    exit 1
  fi
}

# Check that the given path is an existing file. Exit otherwise.
check_file() {
  if ! [ -f "$1" ]; then
    echo "Error: score file '$1' is not an existing file. Exiting."
    exit 1
  fi
}

main "$@"; exit
