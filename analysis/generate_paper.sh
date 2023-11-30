#!/bin/bash
#
# Generate the results for the paper automatically.
# Arguments:
# - $1: File containing a list of commits to generate the results for.
# - $2: The directory where the untangling evaluation results for D4J are stored.
# - $3: The directory where the untangling evaluation results are LLTC4J stored.
# - $4: The directory of the paper repository.
#

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 4 ]] ; then
    echo "usage: $0 <commits-list> <d4j-results-dir> <lltc4j-results-dir> <paper-repository>"
    echo "example: $0 commits.csv ~/evaluation-results ~/papers/untangling-tools-evaluation"
    exit 1
fi

export COMMITS_FILE=$1
export D4J_RESULTS_DIR=$2
export LLTC4J_RESULTS_DIR=$2
export PAPER_REPOSITORY=$4

if ! [ -f "$COMMITS_FILE" ]; then
    echo "Error: commit file '${COMMITS_FILE}' not found. Exiting."
    exit 1
fi

# Check if the path exists and is a directory
if [ ! -d "$PAPER_REPOSITORY" ]; then
  echo "Error: '$PAPER_REPOSITORY' is not an existing directory.  Exiting."
  exit 1
fi

export SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPT_DIR/../src/bash/main/lltc4j/lltc4j_util.sh"

# Temporary directory for intermediate results
TMP_DIR=$(mktemp -d)
export TMP_DIR

# Copy results in a temporary directory to avoid modifying the original results.
mkdir -p "${TMP_DIR}/evaluation"
cp -r "${D4J_RESULTS_DIR}/logs" "${TMP_DIR}/logs"
cp "${D4J_RESULTS_DIR}/metrics.csv" "${TMP_DIR}/metrics.csv"

# Copy commits that are in the given list.
copy_results(){
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

export -f copy_results
tail -n+2 "$COMMITS_FILE" | parallel --colsep "," copy_results {}

# Generate the aggregated scores for the given commits.
if ! cat "${TMP_DIR}/evaluation"/*/scores.csv > "${TMP_DIR}/decomposition_scores.csv" ; then
  echo "No \"scores.csv\" files found under ${TMP_DIR}."
  exit 1
fi

#
# Data
# Directory for the data that is not importable directly into the paper.
# e.g., statistics for the number of decompositions per tool.
# TODO: Replace with suggestion in
# https://gitlab.cs.washington.edu/tschweiz/code-changes-benchmark/-/merge_requests/4#note_210266
#
# Counts the total number of D4J bugs that were evaluated and how many decomposition failed per tool
python analysis/paper/count_missing_results.py "${TMP_DIR}" > "${PAPER_REPOSITORY}/data/missing_decompositions.txt"

# Generates the performance statistics
python analysis/paper/median_performance.py "${TMP_DIR}/decomposition_scores.csv" > "${PAPER_REPOSITORY}/data/performances.tex"

analysis/paper/flexeme_no_changes.sh "${TMP_DIR}" > "${PAPER_REPOSITORY}/data/flexeme_no_changes.txt"

#
# Untangling statistics
#
python src/python/main/analysis/print_group_counts.py --d4j "$D4J_RESULTS_DIR" --lltc4j "$LLTC4J_RESULTS_DIR" > "${PAPER_REPOSITORY}/tables/group-count.tex"
python src/python/main/analysis/print_group_sizes.py --d4j "$D4J_RESULTS_DIR" --lltc4j "$LLTC4J_RESULTS_DIR" > "${PAPER_REPOSITORY}/tables/group-size.tex"

#
# RQ1
#
Rscript analysis/paper/performance_distribution.R "${TMP_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/figures/rq1-performance-distribution.pdf"
Rscript analysis/paper/statistical_analysis_untangling_tool.R "${TMP_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/data/rq1.txt"
Rscript analysis/paper/compare_models.R "${TMP_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/tables/model-comparison.tex" > "${PAPER_REPOSITORY}"/data/model-comparison.txt

#
# RQ2
#
Rscript analysis/paper/statistical_analysis_commit_metrics.R "${TMP_DIR}/decomposition_scores.csv" "${TMP_DIR}/metrics.csv" "${PAPER_REPOSITORY}/data"

#
# Manual Evaluation
#
# TODO: Generate "${TMP_DIR}/changed_lines.csv" with `line_count.sh`
# Rscript analysis/paper/manual_evaluation.R "analysis/manual/d4j-manual-bugs.csv" "${TMP_DIR}/changed_lines.csv" "${TMP_DIR}/combined_decompositions.csv" "${PAPER_REPOSITORY}/tables/manual-evaluation.tex"
