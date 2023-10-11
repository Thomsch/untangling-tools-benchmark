#!/usr/bin/env python3

"""This script looks at all the "truth.csv" files in the given directory and outputs which commits have bug-fixing
changes and non bug-fixing changes.

Arguments:
    --directory. Required argument to specify the root directory where the ground truth CSV files are kept.
"""

import argparse
import os

import pandas as pd

MIXED_CHANGE_LABEL='mixed'


def get_change_type(df: pd.DataFrame) -> str:
    """
    Returns the type of changes in the given dataframe.
    """
    if df.empty:
        return "empty"
    if all(df["group"] == "bugfix"):
        return "bugfix"
    if all(df["group"] == "nonbugfix"):
        return "nonbugfix"
    if df["group"].isin(["bugfix", "nonbugfix"]).sum() == len(df["group"]):
        return MIXED_CHANGE_LABEL

    raise ValueError(
        f"{df['group']} contains an unexpected value in the `group` column. Should be `bugfix` or `nonbugfix`."
    )


def find_mixed_commits(root_dir: str):
    """
    Counts the number of commits with only bug-fixing changes in the given directory.

    Arguments:
    - dir: Root directory where the CSV ground truth is.
    """
    mixed_changes = []
    for root, current_dir, files in os.walk(root_dir):
        for file in files:
            if file == "truth.csv":
                print(current_dir)
                truth_file = os.path.join(root, file)
                df = pd.read_csv(truth_file, header=0)
                change_type = get_change_type(df)
                if change_type == MIXED_CHANGE_LABEL:
                    mixed_changes.append(current_dir)


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

    args = main_parser.parse_args()

    directory = os.path.realpath(args.directory)
    if not os.path.exists(args.groundtruthdir):
        raise ValueError(f"Directory {directory} does not exist.")

    find_mixed_commits(directory)


if __name__ == "__main__":
    main()
