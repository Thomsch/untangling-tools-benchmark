#!/usr/bin/env python3

"""
This script filters the untangling scores to only include commits with mixed changes.
The new untangling results are written to stdout.

Arguments:
    --scores-file. Required argument to specify the file where the decomposition scores are stored.
    --directory. Required argument to specify the root directory where the ground truth CSV files are kept.
"""

import argparse
import os
from typing import List

import pandas as pd

MIXED_CHANGE_LABEL='mixed'


def get_change_type(df: pd.DataFrame) -> str:
    """
    Returns the type of changes in the given dataframe.
    """
    if df.empty:
        return "empty"
    if all(df["group"] == "fix"):
        return "fix"
    if all(df["group"] == "other"):
        return "other"
    if df["group"].isin(["fix", "other"]).sum() == len(df["group"]):
        return MIXED_CHANGE_LABEL

    raise ValueError(
        f"{df['group']} contains an unexpected value in the `group` column. Should be `bugfix` or `nonbugfix`."
    )


def find_mixed_commits(root_dir: str) -> List[str]:
    """
    Returns a list of commit identifier that have mixed changes in format <project_name>_<commit_hash>.

    Arguments:
    - dir: Root directory where the CSV ground truth is.
    """
    mixed_changes = []
    for root, _, files in os.walk(root_dir):
        for file in files:
            if file == "truth.csv":
                truth_file = os.path.join(root, file)
                df = pd.read_csv(truth_file, header=0)
                change_type = get_change_type(df)
                if change_type == MIXED_CHANGE_LABEL:
                    mixed_changes.append(os.path.basename(root))
    return mixed_changes

def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    main_parser = argparse.ArgumentParser(
        prog="extract-mixed-commits.py",
        description="Looks at all the 'truth.csv' files in the given directory and outputs which commits have bug-fixing "
             "changes and non bug-fixing changes.",
    )

    main_parser.add_argument(
        "-d",
        "--directory",
        help="Root directory containing the ground truth files (truth.csv).",
        metavar="PATH",
        required=True,
    )

    main_parser.add_argument(
        "-s",
        "--score-file",
        help="File containing the aggregated decomposition scores.",
        metavar="PATH",
        required=True,
    )

    args = main_parser.parse_args()

    directory = os.path.realpath(args.directory)
    if not os.path.exists(args.directory):
        raise ValueError(f"Directory {directory} does not exist.")

    mixed_changes = find_mixed_commits(directory)
    df_mixed_changes = pd.DataFrame({"commit_identifier": mixed_changes})
    df_mixed_changes[['project_name', 'short_commit']] = df_mixed_changes['commit_identifier'].str.split('_', expand=True)

    df_scores = pd.read_csv(args.score_file, names=["project_name", "commit", "smartcommit", "flexeme", "filebased"])
    df_scores["short_commit"] = df_scores["commit"].apply(lambda x: x[:6])

    keys = list(df_mixed_changes[['project_name', 'short_commit']].columns.values)
    i1 = df_scores.set_index(keys).index
    i2 = df_mixed_changes.set_index(keys).index
    df_mixed_changes = df_scores[i1.isin(i2)]

    # Write the filtered file to the original file
    from io import StringIO
    output = StringIO()
    df_mixed_changes.to_csv(output, columns=['project_name', 'commit', 'smartcommit', 'flexeme', 'filebased'], index=False, header=False)
    print(output.getvalue())

if __name__ == "__main__":
    main()
