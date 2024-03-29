#!/bin/bash
# Sample N bugs from the file containing all bugs.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: sample_bugs.sh <commit_file> <sample_size>'
    echo 'example: sample_bugs.sh data/d4j-bugs.csv 5'
    exit 1
fi

all_commits_file="$1" # The file containing all bugs.
sample_size="$2" # Number of bugs to sample.

if ! [ -f "$all_commits_file" ]; then
    echo "$0: commit file ${all_commits_file} not found. Exiting."
    exit 1
fi

shuf -n "$sample_size" --random-source="$all_commits_file" "$all_commits_file"
