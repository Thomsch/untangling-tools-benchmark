#!/bin/bash

# This script counts how many times a flexeme didn't find a decomposition.
# The script uses the log files to find a specific error message indicating
# that the flexeme didn't find a decomposition.
#
# The script prints the number of times a flexeme didn't find a decomposition
# to stdout.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 1 ]] ; then
    echo 'usage: flexeme_no_changes.sh <untangling-results>'
    exit 1
fi

UNTANGLING_DIR=$1

echo "Generated automatically"
echo "Number of times a flexeme didn't find a decomposition"
grep -rni "No communities detected for" "$UNTANGLING_DIR" | wc -l