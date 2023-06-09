""" Ground Truth Script.

This script generates the ground truth using the original changes and the minimized version of the D4J bug.

The tool takes as input the original changes from stdin and the D4J project name, bug id and output path as parameters.
The result is saved as a csv file at the specified path.
TODO: What is the format of the csv file?

The tests, comments, and imports are ignored from the original changes.
"""

import os
import sys
from collections import defaultdict
from io import StringIO

import numpy as np
import pandas as pd
from unidiff import PatchSet, LINE_TYPE_CONTEXT, LINE_TYPE_REMOVED, LINE_TYPE_ADDED

COL_NAMES = ['file', 'source', 'target']


def from_stdin() -> pd.DataFrame:
    """
    Parses a diff from stdin into a DataFrame.
    """
    return csv_to_dataframe(StringIO(sys.stdin.read()))


def csv_to_dataframe(csv_data: StringIO) -> pd.DataFrame:
    """
    Convert a CSV string stream into a DataFrame.
    """
    df = pd.read_csv(csv_data, names=COL_NAMES, na_values='None')
    df = df.convert_dtypes()  # Forces pandas to use ints in source and target columns.
    return df


def get_d4j_src_path(defects4j_home, project, vid):
    return os.path.join(defects4j_home, "framework/projects", project, "patches", f"{vid}.src.patch")


def get_d4j_test_path(defects4j_home, project, vid):
    """
    Path to the (non-minimized) test patch file in the D4J project.
    """
    return os.path.join(defects4j_home, "framework/projects", project, "patches", f"{vid}.test.patch")


def convert_to_dataframe(patch: PatchSet) -> pd.DataFrame:
    """
    Converts a PatchSet into a DataFrame and filters out tests, comments, imports, non-java files.
    TODO: What is the format of the DataFrame?  Why do you use a dataframe at all?  Would it be possible to use the PatchSet instead?
    """
    ignore_comments = True
    ignore_imports = True
    df = pd.DataFrame(columns=COL_NAMES)
    for file in patch:
        # Skip non-java files. At least one version must have a java extension.
        # When a file is deleted or created, the file name is 'dev/null'.
        if not (file.source_file.lower().endswith(".java") or file.target_file.lower().endswith(".java")):
            continue

        if file.source_file.endswith("Test.java") or file.target_file.endswith("Test.java"):
            continue

        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue

                # TODO: Lines starting with "*" are not always comments.
                if ignore_comments and (line.value.strip().startswith("/*") or
                                                line.value.strip().startswith("*/") or
                                                line.value.strip().startswith("//") or
                                                line.value.strip().startswith("*")):
                    continue
                if ignore_imports and line.value.strip().startswith("import"):
                    continue

                # Ignore whitespace only lines.
                if not line.value.strip():
                    continue

                entry = pd.DataFrame.from_dict({
                    "file": [file.path],
                    "source": [line.source_line_no],
                    "target": [line.target_line_no],
                })
                df = pd.concat([df, entry], ignore_index=True)
    return df


def get_line_map(diff) -> dict:
    """
    Returns a map of line numbers for each changed line in the diff.
    The map is indexed by the line content. The value is a list of tuples (line, source_line_no, target_line_no).
    """
    line_map = defaultdict(list)

    for file in diff:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT: # Ignore context lines.
                    continue
                line_map[str(line)].append((line, line.source_line_no, line.target_line_no))

    return line_map


def invert_patch(patch):
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue

                if line.line_type == LINE_TYPE_ADDED or line.line_type == LINE_TYPE_REMOVED:
                    tmp = line.source_line_no
                    line.source_line_no = line.target_line_no
                    line.target_line_no = tmp

                if line.line_type == LINE_TYPE_ADDED:
                    line.line_type = LINE_TYPE_REMOVED
                elif line.line_type == LINE_TYPE_REMOVED:
                    line.line_type = LINE_TYPE_ADDED

    return patch


def repair_line_numbers(patch_diff, original_diff):
    """
    Replaces the line numbers for the changed lines in the patch with the line numbers from the original diff.
    Returns the updated patch (patch_diff is modified in place).
    """
    # Get the reference line number for the content of each changed line.
    line_map = get_line_map(original_diff)

    # Update the patch with the correct line numbers
    for file in patch_diff:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue

                if str(line) in line_map:
                    line_records = line_map[str(line)]
                    if len(line_records) == 0:
                        print(f"Minimized line '{line.value.rstrip()}' {line.target_line_no, line.source_line_no} is "
                              f"not in the original diff. The minimized line may contain partial changes, "
                              f"new changes, or be incorrectly minimized.", file=sys.stderr)
                        continue

                    original_line = line_records.pop(0)[0]
                    line.source_line_no = original_line.source_line_no
                    line.target_line_no = original_line.target_line_no
                    line.line_type = original_line.line_type
                else:
                    print(f"Line not found ({line.source_line_no}, {line.target_line_no}): '{line}'", file=sys.stderr)
    return patch_diff


def main():
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: ground_truth.py <project> <vid> <path/to/root/results>")
        exit(1)

    if not os.getenv('DEFECTS4J_HOME'):
        print('DEFECTS4J_HOME environment variable not set. Exiting.')
        exit(1)
    defects4j_home = os.getenv('DEFECTS4J_HOME')

    project = args[0]
    vid = args[1]
    out_path = args[2]

    changes_diff = PatchSet.from_string(sys.stdin.read())
    changes_df = convert_to_dataframe(changes_diff)

    # We assume that the minimized d4j patch is a subset of the original diff (changes_diff).
    # If the minimized Defects4J patch contains lines that are not in the original bug-fixing diff, these lines won't
    # be counted as part of the bug-fix with respect to the original bug-fixing diff because they don't exist in that file.
    try:
        src_patch = PatchSet.from_filename(get_d4j_src_path(defects4j_home, project, vid))
        src_patch = invert_patch(src_patch)
        src_patch = repair_line_numbers(src_patch, changes_diff)
        src_patch_df = convert_to_dataframe(src_patch)
    except FileNotFoundError:
        src_patch_df = pd.DataFrame(columns=COL_NAMES)

    # Test is not minimized, so it's not included in the ground truth.
    # test_patch = load_d4j_patch(get_d4j_test_path(defects4j_home, project, vid))
    # test_patch_df = convert_to_dataframe(test_patch)

    # Merge source patch and test patch.
    # minimal_patch = pd.concat([src_patch_df, test_patch_df], axis=0, ignore_index=True)
    minimal_patch = src_patch_df

    # # Check which truth are in changes and tag them as True in a new column.
    ground_truth = pd.merge(changes_df, minimal_patch, on=COL_NAMES, how='left', indicator='group')
    ground_truth['group'] = np.where(ground_truth.group == 'both', 'fix', 'other')
    ground_truth.to_csv(out_path, index=False)


if __name__ == "__main__":
    main()

# LocalWords: dtypes, dataframe
