#!/bin/bash
# Concatenate all `time.csv` files in out/decomposition.
# Run from root directory of this repository.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

find "out/decomposition" -name "time.csv" -type f -exec cat {} + > "out/time.csv"