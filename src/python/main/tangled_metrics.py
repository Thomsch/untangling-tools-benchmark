"""
This module contains the functions to measure the tangled metrics.
"""
import os
import pandas as pd


def read_ground_truth(ground_truth_file: str) -> pd.DataFrame:
    """
    Reads the ground truth from a CSV file.
    """
    if not os.path.exists(ground_truth_file):
        raise FileNotFoundError(f"File {ground_truth_file} does not exist.")

    return pd.read_csv(ground_truth_file, header=0)


def is_tangled_patch(ground_truth: pd.DataFrame):
    """
    Check whether a commit is tangled at the patch level or not.
    A patch is tangled if it contains more than one group otherwise it is a single-concern patch.
    """
    return ground_truth["group"].nunique() > 1


def count_tangled_file(ground_truth: pd.DataFrame):
    """
    Count how many files are tangled in a commit. A file is tangled if it is tagged
    with more than one group.
    """
    return ground_truth.groupby("file")["group"].nunique().gt(1).sum()
