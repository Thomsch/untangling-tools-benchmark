#!/bin/bash
#
# Retrieves the minimal bug-fixing changes for a Defect4J bug.
#
# Saves the results in a table:
# class     | line changed
# Foo.java  | 3
# Foo.java  | 5
# Bar.java  | 230
# Bar.java  | 231
# Bar.java  | 232
#

# Ground truth:
project=$1
vid=$2
repository=$3
truth_out=$4

./scripts/changed_lines.sh "$repository" | python3 src/ground_truth.py "$project" "$vid" "$truth_out"
# Diff-lines is probably not getting the right line numbers (new rather than old file (vn to vbug)).
