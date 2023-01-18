#!/bin/bash

project=$1
vid=$2
export DEFECTS4J_HOME="/Users/thomas/Workplace/defects4j"

echo "Evaluating project $project, bug $vid"

workdir=./tmp/"$project"_"$vid"/

mkdir -p "./tmp" # Create temporary directory

# Checkout defects4j bug
defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

# Calculates the ground truth
echo -ne '\n'
echo -ne 'Calculating ground truth ..................................................\r'
./scripts/ground_truth.sh "$project" "$vid" "$workdir" ./out/evaluation/"$project"/"$vid"/truth.csv
echo -ne 'Calculating ground truth .................................................. OK\r'
echo -ne '\n'

# Run untangling tools in separate processes.

# rm -rf "$workdir" # Deletes temporary directory