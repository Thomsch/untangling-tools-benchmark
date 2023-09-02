#!/usr/bin/env python3

"""
Counts the number of bug-fixing lines and non-bug-fixing lines from the ground truth.
The current implementation does not account for tangled lines.

Command Line Args:
    - path/to/truth/file: Path to truth.csv file
    - project: Defects4J project name
    - bug_id: Defects4J bug id
Returns:
    A lines.csv file corresponding to the input truth.csv file for each D4J bug file.
    CSV header: project,bug_id,fix_lines,nonfix_line
        - project: D4J project name
        - bug_id:  D4J bug id
        - fix_lines: Number of bug-fixing lines
        - nonfix_lines: Number of non bug-fixing lines
"""

import sys

import pandas as pd


def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: count_lines.py <path/to/truth/file> <project> <bug_id>")
        sys.exit(1)

    truth_file = args[0]  # Path to the ground truth: <project-id>/truth.csv
    project = args[1]  # D4J project name
    vid = args[2]  # D4J bug id

    # "df" stands for "dataframe"
    truth_df = pd.read_csv(truth_file).convert_dtypes()

    fix_lines = truth_df["fix"].value_counts().get(True, default=0)
    nonfix_lines = truth_df["fix"].value_counts().get(False, default=0)

    print(f"{project},{vid},{fix_lines},{nonfix_lines}")


if __name__ == "__main__":
    main()
