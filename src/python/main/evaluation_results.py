"""
Utilities to read data from the evaluation results.
"""

import os
import pandas as pd

GROUND_TRUTH_COLUMNS = ["file", "source", "target", "group"]
PERFORMANCE_COLUMNS = [
    "project",
    "commit_id",
    "smartcommit_rand_index",
    "flexeme_rand_index",
    "filename_rand_index",
]


def read_ground_truth(ground_truth_file: str) -> pd.DataFrame:
    """
    Reads the ground truth from a CSV file.
    """
    if not os.path.exists(ground_truth_file):
        raise FileNotFoundError(f"File {ground_truth_file} does not exist.")

    return pd.read_csv(ground_truth_file, header=0)


def read_performance(file: str, dataset_name: str = None) -> pd.DataFrame:
    """
    Read a performance CSV file for a dataset.

    :param file: The CSV file to read as a dataframe
    :param dataset_name: Optional dataset name to add to the dataframe.
    """
    df = pd.read_csv(file, names=PERFORMANCE_COLUMNS)

    if dataset_name:
        df["dataset"] = dataset_name

    return df
