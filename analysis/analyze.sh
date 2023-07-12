#!/bin/bash

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

#
# Generate the results for the paper automatically.
#

if [[ $# -ne 2 ]] ; then
    echo 'usage: analyze.sh <out-dir> <analysis-result-dir>'
    echo 'example: analyze.sh ~/benchmark ~/analysis-results'
    exit 1
fi

BENCHMARK_DIR=$1
ANALYSIS_DIR=$2

mkdir -p "${ANALYSIS_DIR}"

# Counts the total number of D4J bugs that were evaluated and how many decomposition failed per tool
python analysis/count_missing_results.py "${BENCHMARK_DIR}" > "${ANALYSIS_DIR}/missing_results.txt"

# Generates the tables for the number of groups and the group sizes
# The table content is written to DescriptiveStatistics.Rout
python analysis/clean_decompositions.py ~/benchmark-test/evaluation
python analysis/collate_decompositions.py ~/benchmark-test/evaluation > collated_decompositions.csv
R CMD BATCH analysis/DescriptiveStatistics.R

# Generates the performance statistics
analysis/median_performance.py "${BENCHMARK_DIR}/decompositions.csv" > "${ANALYSIS_DIR}/performance.txt"
