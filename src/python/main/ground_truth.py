#!/usr/bin/env python3

"""
Generates the line-wise ground truth using the original changes and the minimized version
of the D4J bug.
Each diff line is classified into either a non-bug-fixing or bug-fixing change.

The tests, comments, and imports are ignored from the original changes.
The current implementation cannot identify tangled lines (i.e. a line that belongs to both groups).

Command Line Args:
    project: D4J Project name
    vid: D4J Bug id
    path/to/root/results: Specified path to store CSV file returned

Returns:
    The ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
    CSV header: {file, source, target, group='fix','other'}
        - file = each Diff Line Object from the original dif generated
        - source = the line removed (-) from buggy version
        - target = the line added (+) to fixed version
"""

import os
import sys
import pandas as pd
from unidiff import PatchSet, LINE_TYPE_CONTEXT, LINE_TYPE_REMOVED, LINE_TYPE_ADDED
import commit_metrics
from collections import deque

COL_NAMES = ["file", "source", "target"]

def convert_to_dataframe(patch: PatchSet) -> pd.DataFrame:
    df = pd.DataFrame(columns=COL_NAMES)
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type != LINE_TYPE_CONTEXT and line.value.strip():
                    entry = pd.DataFrame.from_dict(
                                {
                                    "file": [file.path],
                                    "source": [line.source_line_no],
                                    "target": [line.target_line_no],
                                }
                            )
                    df = pd.concat([df, entry], ignore_index=True)
    return df

def tag_truth_label(original_diff, fix_diff, nonfix_diff):
    original_lines = deque(commit_metrics.flatten_patch_object(original_diff))
    fix_lines = deque(commit_metrics.flatten_patch_object(fix_diff))
    nonfix_lines = deque(commit_metrics.flatten_patch_object(nonfix_diff))
    labels = ['o' for i in range(len(original_lines))]

    i = 0
    while i < len(original_lines):
        line = original_lines[i]
        if len(fix_lines) == 0 and len(nonfix_lines) == 0:
            print("This is a bug")
            return labels
        fix = fix_lines[0] if fix_lines else None
        nonfix = nonfix_lines[0] if nonfix_lines else None
        if not nonfix or str(line) == str(fix) and str(line) != str(nonfix):   # TODO: We can use == for object equality, but only for bug fix lines
            labels[i] = 'fix'
            fix_lines.popleft()
        elif not fix or str(line) == str(nonfix) and str(line) != str(fix):
            labels[i] = 'other'
            nonfix_lines.popleft()
        elif str(line) != str(nonfix) and str(line) != str(fix):
            print("These are tangled lines: ")
            print(str(nonfix))
            print(str(fix))
            fix_lines.popleft()
            nonfix_lines.popleft()
            continue
        else:   # TODO: Does this really happen though?
            labels[i] = 'both'
            fix_lines.popleft()
            nonfix_lines.popleft()
        i += 1
    return labels

def main():
    """
    Implement the logic of the script. See the module docstring for more
    information.
    """

    args = sys.argv[1:]

    if len(args) != 4:
        print("usage: ground_truth.py <project> <vid> <path/to/project/repo> <path/to/root/results>")
        sys.exit(1)

    project = args[0]
    vid = args[1]
    repository = args[2]
    out_path = args[3]

    original_diff = PatchSet.from_filename(os.path.join(repository, "diff", "VC.diff"))
    bug_fix_diff = PatchSet.from_filename(os.path.join(repository, "diff", "BF.diff"))
    nonfix_diff = PatchSet.from_filename(os.path.join(repository, "diff", "NBF.diff"))

    # Convert the diff to a dataframe for easier manipulation.
    # The PatchSet is not easy or efficient to work with because
    # it uses nested iterable objects.
    original_diff_df = convert_to_dataframe(original_diff)
    truth_labels = tag_truth_label(original_diff, bug_fix_diff, nonfix_diff)
    original_diff_df['group'] = truth_labels
    ground_truth_df = original_diff_df

    ground_truth_df.to_csv(out_path, index=False)

if __name__ == "__main__":
    main()

# LocalWords: dtypes, dataframe, bugfix
