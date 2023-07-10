#!/bin/bash
# Concatenate all `time.csv` files in out/decomposition.
# Run from root directory of this repository.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 1 ]] ; then
    echo 'usage: aggregate_time.sh <out_dir>'
    echo 'example: changed_lines.sh ~/untangling-evaluation'
    exit 1
fi

find "$1" -name "time.csv" -type f -exec cat {} +