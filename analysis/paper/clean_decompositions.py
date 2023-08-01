#!/usr/bin/env python3

"""
Clean the results of the decompositions to avoid unclassified line changes with
respect to the ground truth.

File untangling is not included since it has no more changes than the ground
truth.

Input:
- Path to the untangling evaluation directory (e.g. untangling-results/evaluation)

Output:
- For each folder <project>_<bug_id> in the evaluation directory, one CSV file is
    generated for each decomposition result (e.g. smartcommit.csv, flexeme.csv).
    The CSV files are named <decomposition>_clean.csv.
"""

import os
import sys

import pandas as pd


def clean_decomposition(truth_df, tool_df) -> pd.DataFrame:
    """
    Remove unclassified line changes from the tool's decomposition results.
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
    Implement the logic of the script. See the module docstring for more
    """

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
