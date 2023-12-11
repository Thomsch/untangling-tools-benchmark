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


def is_tangled_patch(ground_truth: pd.DataFrame) -> bool:
    """
    Check whether a commit is tangled at the patch level or not.
    A patch is tangled if it contains more than one group otherwise it is a single-concern patch.
    """
    return ground_truth["group"].nunique() > 1


def count_tangled_file(ground_truth: pd.DataFrame) -> int:
    """
    Count how many files are tangled in a commit. A file is tangled if it is tagged
    with more than one group.
    """
    return ground_truth.groupby("file")["group"].nunique().gt(1).sum()
