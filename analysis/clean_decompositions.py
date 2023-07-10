#!/usr/bin/env python3

"""
Clean the decomposition results from Flexeme and SmartCommit for all bugs in the given directory.
The cleaning will remove decomposition results that are not present in the ground truth. For example, SmartCommit will
assign a group to all changed files, including non-Java files. This script will remove those non-Java files from the
decomposition results.

Outputs two CSV files for each bug:
- flexeme_clean.csv: Cleaned results for the Flexeme decomposition
- smartcommit_clean.csv: Cleaned results for the SmartCommit decomposition
"""
import os
import sys

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
    for subdir, _, _ in os.walk(evaluation_root):
        if subdir == evaluation_root:
            continue

        print(f"Cleaning decompositions in {subdir}")

        try:
            truth_file = os.path.join(subdir, "truth.csv")
            truth_df = pd.read_csv(truth_file).convert_dtypes()
        except FileNotFoundError as e:
            print(f"File not found: {e.filename}", file=sys.stderr)
            sys.exit(1)

        decomposition_files = ["smartcommit.csv", "flexeme.csv"]

        for decomposition_file in decomposition_files:
            decomposition_file_clean = decomposition_file.replace(".csv", "_clean.csv")

            try:
                decomposition_df = pd.read_csv(
                    os.path.join(subdir, decomposition_file)
                ).convert_dtypes()

                if decomposition_file == "flexeme.csv":
                    decomposition_df["group"] = decomposition_df["group"].astype(
                        "string"
                    )
            except FileNotFoundError:
                decomposition_df = None

            decomposition_cleaned = clean_decomposition(truth_df, decomposition_df)
            decomposition_cleaned.to_csv(
                os.path.join(subdir, decomposition_file_clean), index=False
            )


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: clean_decompositions.py <path/to/evaluation/folder>")
        sys.exit(1)

    main(os.path.abspath(args[0]))
