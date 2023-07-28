#!/bin/bash
#
# Generate the results for the paper automatically.
# - $1: The directory where the untangling evaluation results are stored.
# - $2: The path of the paper repository.
#

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 2 ]] ; then
    echo 'usage: generate_paper.sh <evaluation-results-folder> <paper-repository>'
    echo 'example: generate_paper.sh ~/evaluation-results ~/papers/untangling-tools-evaluation'
    exit 1
fi

export UNTANGLING_DIR=$1
export PAPER_REPOSITORY=$2

# Temporary directory for intermediate results
export TMP_DIR="${UNTANGLING_DIR}/.tmp"
mkdir -p "${TMP_DIR}"

# In case the paper repository does not exist yet
mkdir -p "${PAPER_REPOSITORY}" # If the directory does not exist, create it
mkdir -p "${PAPER_REPOSITORY}/tables"
mkdir -p "${PAPER_REPOSITORY}/data" # In case the paper repository does not exist yet

#
# Data
# Directory for the data that is not importable directly into the paper.
# e.g., statistics for the number of decompositions per tool.
#

# Counts the total number of D4J bugs that were evaluated and how many decomposition failed per tool
python analysis/paper/count_missing_results.py "${UNTANGLING_DIR}" > "${PAPER_REPOSITORY}/data/missing_decompositions.txt"

# Generates the performance statistics
python analysis/paper/median_performance.py "${UNTANGLING_DIR}/decomposition_scores.csv" > "${PAPER_REPOSITORY}/data/performances.txt"

#
# Tables
#
python analysis/paper/clean_decompositions.py "${UNTANGLING_DIR}/evaluation"
python analysis/paper/combine_decompositions.py "${UNTANGLING_DIR}/evaluation" > "${TMP_DIR}/combined_decompositions.csv"
Rscript analysis/paper/group_size.R "${TMP_DIR}/combined_decompositions.csv" "${PAPER_REPOSITORY}/tables/group-size.tex"
Rscript analysis/paper/group_count.R "${TMP_DIR}/combined_decompositions.csv" "${PAPER_REPOSITORY}/tables/group-count.tex"

#
# RQ1
#
Rscript analysis/paper/performance_distribution.R "${UNTANGLING_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/figures/rq1-performance-distribution.pdf"
Rscript analysis/paper/rq1.R "${UNTANGLING_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/data/rq1.txt"
Rscript analysis/paper/compare_models.R "${UNTANGLING_DIR}/decomposition_scores.csv" "${PAPER_REPOSITORY}/tables/model-comparison.tex"

#
# RQ2
#
Rscript analysis/paper/rq2.R "${UNTANGLING_DIR}/decomposition_scores.csv" "${UNTANGLING_DIR}/metrics.csv" "${PAPER_REPOSITORY}/data/rq2.txt"

#
# Manual Evaluation
#
# TODO: Generate "${TMP_DIR}/changed_lines.csv" with `line_count.sh`
# Rscript analysis/paper/manual_evaluation.R "analysis/manual/d4j-manual-bugs.csv" "${TMP_DIR}/changed_lines.csv" "${TMP_DIR}/combined_decompositions.csv" "${PAPER_REPOSITORY}/tables/manual-evaluation.tex"