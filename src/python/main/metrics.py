"""
Metric utilities
"""
import pandas as pd


def calculate_ground_truth_size_per_commit(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Calculate the number of lines added or deleted in the ground truth for each commit.
    Returns a dataframe with columns 'project', 'commit_id', 'count'.
    """
    return (
        dataframe[["project", "commit_id", "file"]]
        .groupby(["project", "commit_id"])
        .count()
        .reset_index()
        .rename(columns={"file": "count"})
    )
