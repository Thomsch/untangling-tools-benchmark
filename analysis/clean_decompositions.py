#!/usr/bin/env python3
## TODO: What is the definition of "clean"?  That is used in the name of this script and throughout the documentation, but it isn't defined, so I don't know what this script does.
"""
Clean the decomposition results from Flexeme and SmartCommit for all bugs in the given directory.
Outputs two CSV files for each bug:
- flexeme_clean.csv: Cleaned results for the Flexeme decomposition
- smartcommit_clean.csv: Cleaned results for the SmartCommit decomposition
"""
import os
import sys
from os import path

import pandas as pd


def clean_decomposition(truth_df, tool_df) -> pd.DataFrame:
    """
    Clean changes
    """
    if tool_df is None:
        tool_df = truth_df.copy()
        tool_df["group"] = "o"
        return tool_df

    df = pd.merge(
        truth_df,
        tool_df,
        on=["file", "source", "target"],
        how="left",
        suffixes=("_truth", "_tool"),
    )
    df.drop(["group_truth"], axis=1, inplace=True)
    df["group_tool"] = df["group_tool"].fillna(
        "o"
    )  # Fill changed lines that are unclassified as other changes ('o').
    df.rename(columns={"group_tool": "group"}, inplace=True)
    return df


def main(evaluation_root):
    """
    Clean the results of the decompositions to avoid unclassified line changes with respect to the
    ground truth.
    """
    # File untangling is not included since it's made from the ground truth already.

    # Iterate through each subdirectory in the parent directory
    for subdir, dirs, files in os.walk(evaluation_root):
        for file in files:
            if file == "truth.csv":
                truth_file = os.path.join(subdir, file)

                try:
                    truth_df = pd.read_csv(truth_file).convert_dtypes()
                except FileNotFoundError as e:
                    print(f"File not found: {e.filename}", file=sys.stderr)
                    sys.exit(1)

                smartcommit_file = path.join(subdir, "smartcommit.csv")
                smartcommit_clean_file = path.join(subdir, "smartcommit_clean.csv")
                flexeme_file = path.join(subdir, "flexeme.csv")
                flexeme_clean_file = path.join(subdir, "flexeme_clean.csv")

                try:
                    smartcommit_df = pd.read_csv(smartcommit_file).convert_dtypes()
                except FileNotFoundError:
                    smartcommit_df = None

                try:
                    flexeme_df = pd.read_csv(flexeme_file).convert_dtypes()
                    flexeme_df["group"] = flexeme_df["group"].astype("string")
                except FileNotFoundError:
                    flexeme_df = None

                smartcommit_cleaned = clean_decomposition(truth_df, smartcommit_df)
                flexeme_cleaned = clean_decomposition(truth_df, flexeme_df)

                smartcommit_cleaned.to_csv(smartcommit_clean_file, index=False)
                flexeme_cleaned.to_csv(flexeme_clean_file, index=False)


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: clean_decompositions.py <path/to/benchmark/evaluation/folder>")
        sys.exit(1)

    main(os.path.abspath(args[0]))
