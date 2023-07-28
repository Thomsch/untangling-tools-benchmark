#!/usr/bin/env python3

"""
Generates the line-wise ground truth.

The ground truth classifies each diff line as a non-bug-fixing change
(group='other'), a bug-fixing change (group='fix'), or a tangled change
(group='both').

The tests, comments, and imports are ignored from the original changes.
The current implementation cannot identify tangled lines (i.e. a line that belongs to both groups).

Command Line Args:
    project: D4J Project name
    vid: D4J Bug id
    path/to/root/results: Specified file to store CSV file returned

Returns:
    The ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
    CSV header: {file, source, target, group='fix','other','both'}
        - file = each Diff Line Object from the original dif generated
        - source = the line removed (-) from buggy version
        - target = the line added (+) to fixed version
"""

from collections import deque
import os
import sys
import pandas as pd
from unidiff import PatchSet, LINE_TYPE_CONTEXT
from diff_metrics import flatten_patch_object

COL_NAMES = ["file", "source", "target"]


def convert_to_dataframe(patch: PatchSet) -> pd.DataFrame:
    """
    Converts a PatchSet into a DataFrame and filters out tests, comments, imports, non-Java files.
    The filtering is done during the conversion to avoid iterating over the patch twice.

    The dataframe has the following columns:
        - file (str): Path of the file
        - source (int): Line number when the line is removed or changed
        - target (int): Line number when the line is added or changed
    """
    df = pd.DataFrame(columns=COL_NAMES)
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type != LINE_TYPE_CONTEXT and line.value.strip():
                    entry = pd.DataFrame.from_dict(
                        {
                            # Since a line can only be either added or removed, one of the two will always be empty.
                            "file": [file.path],
                            "source": [line.source_line_no],
                            "target": [line.target_line_no],
                        }
                    )
                    df = pd.concat([df, entry], ignore_index=True)
    return df


def classify_diff_lines(original_diff, fix_diff, nonfix_diff):
    """
    Tag the correct truth label to each line in original diff.

    Returns a list of labels, one for each line in the original diff:
    - 'fix': A bug-fixing line
    - 'other': A non bug-fixing line
    - 'both': A tangled line.
    Note: The tangled line may be changes that cancel out in the BF and NBF diffs and thus does not exist in VC.diff.
    """
    original_lines = deque(
        [str(line) for line in flatten_patch_object(original_diff)]
    )  # Generated 3 Queue objects
    fix_lines = deque([str(line) for line in flatten_patch_object(fix_diff)])
    nonfix_lines = deque([str(line) for line in flatten_patch_object(nonfix_diff)])
    labels = [
        "other" for i in range(len(original_lines))
    ]  # Place holder for the truth label

    i = 0
    line_is_tangled = (
        False  # A global mode that indicates if 2 lines are part of tangled fix
    )
    while i < len(original_lines):  # Align the fix lines and nonfix lines as Queues.
        line = original_lines[i]
        print("LINE", line)
        if len(fix_lines) == 0 and len(nonfix_lines) == 0:
            print("This is a bug")
            return labels
        fix = fix_lines[0] if fix_lines else None
        nonfix = nonfix_lines[0] if nonfix_lines else None
        print("fix line is: ", fix)
        print("nonfix line is: ", nonfix)
        # Pop each line out of original diff and compare to the 2 heads of fix_lines and nonfix_queues.
        if (
            line == fix and line != nonfix
        ):  # If line is identical to head of fix_lines, it is bug-fixing
            labels[i] = "fix"
            fix_lines.popleft()
        elif (
            line == nonfix and line != fix
        ):  # If line is identical to head of nonfix_lines, it is non bug-fixing
            labels[i] = "other"
            nonfix_lines.popleft()
        elif line not in (
            nonfix,
            fix,
        ):  # If line is different from both: the 2 heads of fix and nonfix are tangled changes
            if fix and nonfix and fix.split()[-1].strip() == nonfix.split()[-1].strip():
                print("These are tangled lines: ", file=sys.stderr)
                fix_lines.popleft()
                nonfix_lines.popleft()
                line_is_tangled = True  # Switched tangled line mode on
                continue
            # Else, switch truth labelling scheme, always match with first occurrence
            if line in fix_lines:
                labels[i] = "fix"
                fix_lines.remove(line)
            elif line in nonfix_lines:
                labels[i] = "other"
                nonfix_lines.remove(line)
            else:
                # The tangled line may be changes that cancel out in the BF and NBF diffs and thus does not exist in VC.diff.
                # This also handles the bug in Defects4J, when lines belonging to different hunks are duplicated and cancel out
                i += 1
                continue
        else:
            labels[i] = "both"
            print("There is a line tagged both!", file=sys.stderr)
            fix_lines.popleft()
            nonfix_lines.popleft()
        if line_is_tangled and labels[i] == "fix":
            labels[i] = "both"
            line_is_tangled = False  # Switch tangled mode off
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
    original_diff = PatchSet.from_filename(
        os.path.join(repository, "diff", "VC_clean.diff"),
        encoding="latin-1",  # latin-1 is the best choice for an ASCII-compatible encoding
    )
    bug_fix_diff = PatchSet.from_filename(
        os.path.join(repository, "diff", "BF.diff"), encoding="latin-1"
    )
    nonfix_diff = PatchSet.from_filename(
        os.path.join(repository, "diff", "NBF.diff"), encoding="latin-1"
    )

    original_diff_df = convert_to_dataframe(original_diff)
    truth_labels = classify_diff_lines(original_diff, bug_fix_diff, nonfix_diff)
    original_diff_df["group"] = truth_labels
    ground_truth_df = original_diff_df

    ground_truth_df.to_csv(out_path, index=False)


if __name__ == "__main__":
    main()
