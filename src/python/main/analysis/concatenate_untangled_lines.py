#!/usr/bin/env python3

"""
Concatenate the untangled lines from all the tools into a single CSV file printed on the standard output.
The CSV file contains the following columns:
- project: the name of the project
- bug_id: the ID of the Defects4J bug
- treatment: the treatment that classified this line change into <group>
- file: the path to the file
- source: the source line number (for deletions)
- target: the target line number (for insertions)
- group: the group that the file belongs to
"""

import os
import sys

import pandas as pd

included_tools = ["flexeme.csv", "smartcommit.csv", "filename.csv"]

def normalize_untangled_lines(truth_df, untangled_lines_df) -> pd.DataFrame:
    """
    Normalize the untangled lines to match the ground truth CSV file.
    Specifically, the following changes are made:
    - Untangled lines that are not in the ground truth are removed.
    - Untangled lines that are missing compared to the ground truth are added with the group 'o'.
    """
    if untangled_lines_df is None:
        tool_df = truth_df.copy()
        tool_df["group"] = "o"
        return tool_df

    df = pd.merge(
        truth_df,
        untangled_lines_df,
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


def concatenate_untangled_lines_for_commit(commit_dir) -> pd.DataFrame:
    """
    Concatenate the untangled lines from all the tools into a single dataframe.
    Also concatenate the ground truth.

    Arguments:
        commit_dir: Path to the directory containing the CSV files containing the untangled lines.
    """
    truth_path = os.path.join(commit_dir, "truth.csv")
    if not os.path.exists(truth_path):
        return pd.DataFrame()

    truth_df = pd.read_csv(truth_path)

    concatenate_df = pd.DataFrame(columns=["treatment", "file", "source", "target", "group"])
    for csv_filename in os.listdir(commit_dir):
        if csv_filename not in included_tools:
            continue
        untangled_lines_df = pd.read_csv(os.path.join(commit_dir, csv_filename))
        untangled_lines_normalize_df = normalize_untangled_lines(truth_df, untangled_lines_df)
        untangled_lines_normalize_df["treatment"] = csv_filename
        concatenate_df = pd.concat([concatenate_df, untangled_lines_normalize_df], ignore_index=True)

    truth_df["treatment"] = "truth.csv"
    concatenate_df = pd.concat([concatenate_df, truth_df], ignore_index=True)
    return concatenate_df

def main(evaluation_dir):
    """
    Implement the logic of the script. See the module docstring for more
    information.
    """

    # Iterate through each bug directory in the `evaluation` directory of the untangling directory.
    concatenate_df = pd.DataFrame(columns=["project", "bug_id", "treatment", "file", "source", "target", "group"])

    for bug_tag in os.listdir(evaluation_dir):
        bug_dir = os.path.join(evaluation_dir, bug_tag)
        if not os.path.isdir(bug_dir):
            continue

        # Extract project and id from the subdirectory name
        split = bug_tag.split("_")
        if len(split) != 2:
            print(
                f"Invalid subdirectory name: {bug_tag}."
                f" Expected to be of the form <project>_<bug_id>.",
                file=sys.stderr,
            )
            continue
        project, bug_id = split

        untangled_lines_for_commit_df = concatenate_untangled_lines_for_commit(bug_dir)
        untangled_lines_for_commit_df["project"] = project
        untangled_lines_for_commit_df["bug_id"] = bug_id
        concatenate_df = pd.concat([concatenate_df, untangled_lines_for_commit_df], ignore_index=True)
    print(concatenate_df.to_csv(index=False, header=True))

if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: concatenate_untangled_lines.py <path/to/untangling/evaluation/folder>")
        print("example: concatenate_untangled_lines.py untangling-evaluation/evaluation")
        sys.exit(1)

    main(os.path.abspath(args[0]))
