#!/bin/bash
#
# Print the group count table for the paper in latex format.
# The table contains summary statistics for the number of groups generated by
# each tool for each dataset across all commits.
# The table is printed to stdout.
#
# Arguments:
# - $1: CSV File containing the untangled lines for the first dataset
# - $2: CSV File containing the untangled lines for the second dataset
#
# The CSV files are expected to have the following columns:
#- project: the name of the project
#- bug_id: the ID of the Defects4J bug
#- treatment: the treatment that classified this line change into <group>
#- file: the path to the file
#- source: the source line number (for deletions)
#- target: the target line number (for insertions)
#- group: the group that the file belongs to
#

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 2 ]] ; then
    echo "usage: $0 <untangled_lines_dataset_1.csv> <untangled_lines_dataset_2.csv>"
    echo "example: $0 commits.csv untangled_lines_d4j.csv untangled_lines_lltc4j.csv"
    exit 1
fi

export UNTANGLED_LINES_DATASET_1=$1
export UNTANGLED_LINES_DATASET_2=$2
