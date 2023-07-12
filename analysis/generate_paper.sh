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
    echo 'usage: analyze.sh <evaluation-results-folder> <paper-repository>'
    echo 'example: analyze.sh ~/evaluation-results ~/papers/untangling-tools-evaluation'
    exit 1
fi

UNTANGLING_DIR=$1
PAPER_REPOSITORY=$2

# Temporary directory for intermediate results
TMP_DIR="${UNTANGLING_DIR}/.tmp"
mkdir -p "${TMP_DIR}"

# In case the paper repository does not exist yet
mkdir -p "${PAPER_REPOSITORY}" # If the directory does not exist, create it
mkdir -p "${PAPER_REPOSITORY}/tables"
mkdir -p "${PAPER_REPOSITORY}/data" # In case the paper repository does not exist yet

#
# Data directory for the data that is not importable directly into the paper.
# e.g., statistics for the number of decompositions per tool.
#

# Counts the total number of D4J bugs that were evaluated and how many decomposition failed per tool
python analysis/paper/count_missing_results.py "${UNTANGLING_DIR}" > "${PAPER_REPOSITORY}/data/missing_results.txt"

# Generates the performance statistics
python analysis/paper/median_performance.py "${UNTANGLING_DIR}/decomposition_scores.csv" > "${PAPER_REPOSITORY}/data/performance.txt"

#
# Tables
#
python analysis/paper/clean_decompositions.py "${UNTANGLING_DIR}/evaluation"
python analysis/paper/combine_decompositions.py "${UNTANGLING_DIR}/evaluation" > "${TMP_DIR}/combined_decompositions.csv"
Rscript analysis/paper/group_size.R "${TMP_DIR}/combined_decompositions.csv" "${PAPER_REPOSITORY}/tables/group-size.tex"
Rscript analysis/paper/group_count.R "${TMP_DIR}/combined_decompositions.csv" "${PAPER_REPOSITORY}/tables/group-count.tex"