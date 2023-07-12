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
from collections import deque
import os
import sys
import pandas as pd
from unidiff import PatchSet, LINE_TYPE_CONTEXT
from clean_artifacts import clean_diff
from commit_metrics import flatten_patch_object

COL_NAMES = ["file", "source", "target"]


def convert_to_dataframe(patch: PatchSet) -> pd.DataFrame:
    """
    Convert the nested PatchSet object to a Dataframe to:
    - Remove comments, blank lines, and import statements
    - Easier manipulate data as PatchSet is a nested iterable Object.
    """
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
    """
    Tag the correct truth label to each line in original diff by aligining the fix lines and nonfix lines as Queues.
    Pop each line out of original diff and compare to the 2 heads of fix_lines and nonfix_queues.
    Returns a List of labels for each line:
    - 'fix': A bug-fixing line
    - 'other': A non bug-fixing line
    - 'both': A tangled line.
    Note: The tangled line may be changes that cancel out in the BF and NBF diffs and thus does not exist in VC.diff.
    # TODO: We can use == for object equality, but only for bug fix lines
    """
    original_lines = deque(
        flatten_patch_object(original_diff)
    )  # Generated 3 Queue objects
    fix_lines = deque(flatten_patch_object(fix_diff))
    nonfix_lines = deque(flatten_patch_object(nonfix_diff))
    labels = [
        "o" for i in range(len(original_lines))
    ]  # Place holder for the truth label

    i = 0
    while i < len(original_lines):
        line = original_lines[i]
        if len(fix_lines) == 0 and len(nonfix_lines) == 0:
            print("This is a bug")
            return labels
        fix = fix_lines[0] if fix_lines else None
        nonfix = nonfix_lines[0] if nonfix_lines else None
        if (
            not nonfix or str(line) == str(fix) and str(line) != str(nonfix)
        ):  # If line is identical to head of fix_lines, it is bug-fixing
            labels[i] = "fix"
            fix_lines.popleft()
        elif (
            not fix or str(line) == str(nonfix) and str(line) != str(fix)
        ):  # If line is identical to head of nonfix_lines, it is non bug-fixing
            labels[i] = "other"
            nonfix_lines.popleft()
        elif str(line) != str(nonfix) and str(line) != str(
            fix
        ):  # If line is different from both: the 2 heads of fix and nonfix are tangled changes
            print("These are tangled lines: ")
            print(str(nonfix))
            print(str(fix))
            fix_lines.popleft()
            nonfix_lines.popleft()
            continue
        else:  # TODO: Does this really happen though?
            labels[i] = "both"
            fix_lines.popleft()
            nonfix_lines.popleft()
        i += 1
    return labels


def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    args = sys.argv[1:]

    if len(args) != 2:
        print("usage: ground_truth.py <path/to/project/repo> <path/to/root/results>")
        sys.exit(1)

    repository = args[0]
    out_path = args[1]
    clean_diff(
        os.path.join(repository, "diff", "VC.diff")
    )  # Remove blank lines, comments, import statements from VC diff for tangled line and hunk support
    original_diff = PatchSet.from_filename(os.path.join(repository, "diff", "VC.diff"))
    bug_fix_diff = PatchSet.from_filename(os.path.join(repository, "diff", "BF.diff"))
    nonfix_diff = PatchSet.from_filename(os.path.join(repository, "diff", "NBF.diff"))

    original_diff_df = convert_to_dataframe(original_diff)
    truth_labels = tag_truth_label(original_diff, bug_fix_diff, nonfix_diff)
    original_diff_df["group"] = truth_labels
    ground_truth_df = original_diff_df

    ground_truth_df.to_csv(out_path, index=False)


if __name__ == "__main__":
    main()
