#!/bin/bash

# Read a file containing the untangling log for a dataset and print the
# count of the outcomes. e.g., how many decompositions were successful,
# how many failed, etc.
#
# Arguments:
# - $1: The path to the untangling log file.
#
# TODO: Add an option to skip the last n lines because the log file sometimes contains the output of the `time` command.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 1 ]] ; then
    echo "usage: $0 <untangling-log-file>"
    exit 1
fi

file_path=$1

if [ ! -f "$file_path" ]; then
  echo "Error: '$file_path' does not exists.  Exiting."
  exit 1
fi

awk '{split($2, labels, " "); for (i in labels) count[labels[i]]++} END {for (label in count) print label ": " count[label] " times"}' "$file_path"
