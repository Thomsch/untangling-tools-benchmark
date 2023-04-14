#!/bin/bash

# Concatenate all `time.csv` files in out/decomposition.
# Run from root directory of this repository.

find "out/decomposition" -name "time.csv" -type f -exec cat {} + > "out/time.csv"