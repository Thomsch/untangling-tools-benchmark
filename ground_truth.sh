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
project="Lang"
vid="1"
patch_src="/Users/thomas/Workplace/defects4j/framework/projects/$project/patches/$vid.src.patch"
patch_test="/Users/thomas/Workplace/defects4j/framework/projects/$project/patches/$vid.test.patch"
truth_out="./out/evaluation/$project/$vid/truth.csv"
repository="./tmp"

./changed_lines.sh "$repository" | python3 ground_truth.py "$truth_out"
# Diff-lines is probably not getting the right line numbers (new rather than old file (vn to vbug)).
