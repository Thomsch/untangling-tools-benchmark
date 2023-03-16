#!/bin/bash
#
# Retrieves the minimal bug-fixing changes for a Defect4J bug.
#
project=$1
vid=$2
repository=$3
truth_out=$4
commit=$5

export DEFECTS4J_HOME="/Users/thomas/Workplace/defects4j"
./scripts/changed_lines.sh "$project" "$vid" "$repository" "$commit" | python3 src/ground_truth.py "$project" "$vid" "$truth_out"
