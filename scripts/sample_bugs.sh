#!/bin/bash

# Sample N bugs from the file containing all bugs.

all_commits=$1 # Path to the file containing all bugs.
sample_size=$2 # Number of bugs to sample.

if ! [[ -f "$all_commits" ]]; then
    echo "File ${all_commits} not found. Exiting."
    exit 1
fi

shuf -n "$sample_size" "$all_commits"