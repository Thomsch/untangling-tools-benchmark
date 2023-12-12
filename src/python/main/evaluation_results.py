"""
Utilities to read data from the evaluation results.
"""

import os
from typing import List

import pandas as pd

import tangled_metrics

from pandas.api.types import CategoricalDtype


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


def read_metrics(file: str, dataset_name=None) -> pd.DataFrame:
    """
    Read a metrics CSV file for a dataset. This CSV file is expected to have a header.

    :param file: The CSV file to read as a dataframe
    :param dataset_name: Optional dataset name to add to the dataframe.
    """
    df = pd.read_csv(file, header=0)

    # if vid is a column, rename it to 'commit_id'
    if "vid" in df.columns:
        df = df.rename(columns={"vid": "commit_id"})

    if "tangled_level" in df.columns:
        df["tangled_level"] = df["tangled_level"].astype(
            CategoricalDtype(categories=tangled_metrics.TANGLED_LEVELS, ordered=True)
        )

    # Convert the commit_id column to string for D4J bug ids.
    df["commit_id"] = df["commit_id"].astype(str)

    if dataset_name:
        df["dataset"] = dataset_name

    return df


def retrieve_ground_truth_files(results_dir: str) -> List[str]:
    """
    Retrieves the ground truth files from the given directory.
    """
    ground_truth_files = []
    for root, _, files in os.walk(results_dir):
        for file in files:
            if file == "truth.csv":
                ground_truth_files.append(os.path.join(root, file))

    return ground_truth_files
