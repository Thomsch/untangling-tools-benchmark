""" Ground Truth Script.

This script generates the ground truth using the original changes and the minimized version of the D4J bug.

The tool takes as input the original changes from stdin and the D4J project name, bug id and output path as parameters.
The result is saved as a csv file at the specified path.
"""

import os
import sys
from io import StringIO

import numpy as np
import pandas as pd
from unidiff import PatchSet, LINE_TYPE_CONTEXT, LINE_TYPE_REMOVED, LINE_TYPE_ADDED

import parse_patch

COL_NAMES = ['file', 'source', 'target']


def from_stdin() -> pd.DataFrame:
    """
    Parses a diff from stdin into a DataFrame.
    """
    return csv_to_dataframe(StringIO(sys.stdin.read()))


def from_file(path) -> pd.DataFrame:
    """
    Parses a diff from a file into a DataFrame.
    """
    data = parse_patch.from_file(path)
    return csv_to_dataframe(StringIO(data))


def csv_to_dataframe(csv_data: StringIO) -> pd.DataFrame:
    """
    Convert a CSV string stream into a DataFrame.
    """
    df = pd.read_csv(csv_data, names=COL_NAMES, na_values='None')
    df = df.convert_dtypes()  # Forces pandas to use ints in source and target columns.
    return df


def get_d4j_src_path(defects4j_home: str, project: str, vid: int):
    return os.path.join(defects4j_home, "framework/projects", project, "patches", f"{vid}.src.patch")


def get_d4j_test_path(defects4j_home, project, vid):
    return os.path.join(defects4j_home, "framework/projects", project, "patches", f"{vid}.test.patch")


def convert_to_dataframe(patch: PatchSet) -> pd.DataFrame:
    """
    Converts a PatchSet into a DataFrame.
    """
    df = pd.DataFrame(columns=COL_NAMES)
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                entry = pd.DataFrame.from_dict({
                    "file": [file.path],
                    "source": [line.source_line_no],
                    "target": [line.target_line_no],
                })
                df = pd.concat([df, entry], ignore_index=True)
    return df


def load_d4j_patch(patch_path: str, original_changes=None) -> PatchSet:
    patch = PatchSet.from_filename(patch_path)
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue

                if line.line_type == LINE_TYPE_ADDED:
                    line.line_type = LINE_TYPE_REMOVED
                    line.source_line_no = line.target_line_no
                    line.target_line_no = line.source_line_no
                elif line.line_type == LINE_TYPE_REMOVED:
                    line.line_type = LINE_TYPE_ADDED
                    line.source_line_no = line.target_line_no
                    line.target_line_no = line.source_line_no

                if original_changes:
                    original_line = original_changes[str(line)]
                    if original_line is not None:
                        line.source_line_no = original_line.source_line_no
                        line.target_line_no = original_line.target_line_no
                        line.line_type = original_line.line_type
    return patch


def main():
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: file.py <project> <vid> <path/to/root/results>")
        exit(1)

    if not os.getenv('DEFECTS4J_HOME'):
        print('DEFECTS4J_HOME environment variable not set. Exiting.')
        exit(1)
    defects4j_home = os.getenv('DEFECTS4J_HOME')

    project = args[0]
    vid = args[1]
    out_path = args[2]

    changes_diff = PatchSet.from_string(sys.stdin.read())
    changes = {}
    for file in changes_diff:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                if str(line) in changes:
                    print(f"Duplicate change: {str(line)}", file=sys.stderr)
                    continue
                changes[str(line)] = line
    changes_df = convert_to_dataframe(changes_diff)

    # Assumption: No duplicate changes in the patch.
    # Assumption: No minimization within a line (i.e., either the line is included or not).
    src_patch = load_d4j_patch(get_d4j_src_path(defects4j_home, project, vid), changes)
    src_patch_df = convert_to_dataframe(src_patch)

    # Test is not minimized so all the changes are part of the ground truth.
    test_patch = load_d4j_patch(get_d4j_test_path(defects4j_home, project, vid))
    test_patch_df = convert_to_dataframe(test_patch)

    # Merge source patch and test patch.
    minimal_patch = pd.concat([src_patch_df, test_patch_df], axis=0, ignore_index=True)
    # minimal_patch = from_defect4j_patches(defects4j_home, project, vid)

    # # Check which truth are in changes and tag them as True in a new column.
    ground_truth = pd.merge(changes_df, minimal_patch, on=COL_NAMES, how='left', indicator='fix')
    ground_truth['fix'] = np.where(ground_truth.fix == 'both', True, False)
    ground_truth.to_csv(out_path, index=False)


if __name__ == "__main__":
    main()

# LocalWords: dtypes, dataframe
