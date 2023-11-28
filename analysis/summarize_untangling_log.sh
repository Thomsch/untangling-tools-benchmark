#!/bin/bash

# Summarizes the given untangling log by printing how many times each untangling status appears.
#
# The script assumes that the log file is in the following format:
# <commit_identifier> <status> <elapsed_time> <path/to/log/file/for/commit>
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
  echo "Error: '$file_path' does not exist.  Exiting."
  exit 1
fi

awk '{print $2}' "$file_path" | sort | uniq -c