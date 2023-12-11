"""
This module contains the functions to measure the tangled metrics.
"""
import pandas as pd


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
