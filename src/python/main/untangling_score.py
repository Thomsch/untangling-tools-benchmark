#!/usr/bin/env python3

"""
Calculates the Rand Index for untangling results of 3 methods: SmartCommit, Flexeme, and File-based.

Command Line Args:
    - evaluation/project/bug_id: Path to the evaluation subfolder of the D4J bug containing CSV
      files for: ground truth, 3 untangling results
    - project: D4J project name
    - bug_id: D4J bug id
Returns:
    A scores.csv file in the /evaluation/<D4J bug id> subfolder.
    CSV header: {project,vid,smartcommit_score,flexeme_score,file_untangling_score}
        - project: D4J project name
        - vid: D4J bug id
        - smartcommit_score: The Rand Index score for SmartCommit untangling results
        - flexeme_score: The Rand Index score for Flexeme untangling results
        - file_untangling_score: The Rand Index score for File-based untangling results
"""

import sys
from os import path

import pandas as pd
from sklearn import metrics


def merge_nonbugfixing_changes(df: pd.DataFrame) -> pd.DataFrame:
    """
    Merge clusters of purely non-bug-fixing changes into one group named 'o'.
    Args:
        df: a DataFrame with columns = ['file','source','target','group_truth','group_tool']
                group_truth: 'fix' or 'other'
                group_tool: depends on the tool.
                    For Flexeme, group labels are non-negative integers casted as string, e.g. '0','1','2',etc.
                    For SmartCommit, group labels are strings in the format: 'group0','group1', etc.
    Returns:
        A DataFrame modified in-place, with a less fine-grained classification as purely non-bug-fixing groups is considered 'other'.
    """
    groups = is_only_nonbugfixing_change(df)

    # 'adjusted_group' is a new Boolean column: True if group_tool is purely non-bug-fixing
    # updates all purely-non-bug-fixing lines to 'other' in 'group_tool'
    df["adjusted_group"] = df["group_tool"].isin(groups[groups].index)
    df.loc[df["adjusted_group"], "group_tool"] = "o"

    return df.drop(["other_change", "adjusted_group"], axis=1)


def is_only_nonbugfixing_change(df: pd.DataFrame) -> pd.Series:
    """
    For each group generated by tool, return whether the group contains only non bug-fixing changes or not.
    Args:
        df: a DataFrame with columns = ['file','source','target','group_truth','group_tool']
    Returns:
        a Series [Name: group_tool, boolean] indicating for each group generated by the tool,
            True = all lines in that group are non-bug-fixing changes
            False = at least one line in that group is a bug-fixing change
    """
    df["group_truth_bool"] = df["group_truth"] == "fix"  # Convert to boolean.

    # New column to keep track of non bug-fixing changes.
    df["other_change"] = ~df["group_truth_bool"]

    # Which groups only have non-bug-fixing changes.
    return df.groupby("group_tool")["other_change"].all()


def calculate_score_for_tool(truth_df, tool_df):
    """
    Evaluates the tool with Rand Index as metric. The tool classifies each line to a group label (as Strings).
    All lines that were unlabelled are treated as 'other' (i.e. non-bug-fixing changes).
    All groups that do not contain any bug-fixing line will be treated as 'other'.

    Args:
        truth_df: The ground truth returned by ground_truth.py. CSV header: {file, source, target, group='fix','other'}
        tool_df: The clustering results returne by the respective tool. CSV header: {file, source, target, group'}
            group': String representing group assigned by tool.
                    Flexeme: non-negative integers casted as string e.g., '0','1','2',etc.
                    SmartCommit: strings in the format: e.g., 'group0','group1', etc.
    Returns:
        The Rand Index between the ground truth and a tool.
    """
    if tool_df is None:
        tool_df = truth_df.copy()
        tool_df["group"] = "o"

    # group_truth = 'fix' or 'other', group_tool = String representing group assigned by tool
    df = pd.merge(
        truth_df,
        tool_df,
        on=["file", "source", "target"],
        how="left",
        suffixes=["_truth", "_tool"],
    )
    # Fill changed lines that are unclassified as other changes ('o').
    df["group_tool"] = df["group_tool"].fillna("o")

    # Adjust cluster to not penalize multiple groups containing exclusively
    # non bug fixing changes.
    df_adjusted = merge_nonbugfixing_changes(df)

    # Group labels predicted by the tool.
    # Series [Name: group_tool, dtype: string]
    labels_pred = df_adjusted["group_tool"]

    # Group labels from the ground truth.
    # Series [Name: group_truth, dtype: string]
    labels_true = df_adjusted["group_truth"]

    # The adjusted rand score (not the same as the adjusted clusters above!)
    # give a score of 0 when the fix is divided in multiple groups, which is unfair.
    # smartcommit_score = metrics.adjusted_rand_score(labels_truth, labels_pred)
    return metrics.rand_score(labels_true, labels_pred)


def main(args):
    """
    Implement the logic of the script. See the module docstring.

    Args:
        args: command line arguments
    """
    if len(args) != 3:
        print(
            "usage: untangling_score.py <evaluation/project/bug_id> <project> <bug_id>"
        )
        sys.exit(1)

    root = args[0]
    project = args[1]
    vid = args[2]

    # Convert ground truth into a DataFrame
    try:
        truth_file = path.join(root, "truth.csv")
        truth_df = pd.read_csv(truth_file).convert_dtypes()
    except FileNotFoundError as e:
        print(f"File not found: {e.filename}", file=sys.stderr)
        sys.exit(1)

    tool_csv = ["smartcommit.csv", "flexeme.csv", "file_untangling.csv"]

    # Generate array of RandIndex scores (type='float') for each tool, initialized to 0.0
    tool_scores = [0.0] * len(tool_csv)

    # Cast each tool's group labels into String format and pair with ground truth to calculate Rand Index
    for i, value in enumerate(tool_csv):
        tool_decomposition_file = path.join(root, value)
        try:
            tool_df = pd.read_csv(tool_decomposition_file).convert_dtypes()
            tool_df["group"] = tool_df["group"].astype("string")
        except FileNotFoundError:
            tool_df = None

        # Add Rand Index in respective tool order
        tool_scores[i] = calculate_score_for_tool(truth_df, tool_df)

    print(f"{project},{vid},{tool_scores[0]},{tool_scores[1]},{tool_scores[2]}")


if __name__ == "__main__":
    args = sys.argv[1:]
    main(args)
