#!/bin/bash

# Aggregates all decomposition elapsed time
# Run from root directory of this repository.

find "out/decomposition" -name "time.csv" -type f -exec cat {} + > "out/time.csv"