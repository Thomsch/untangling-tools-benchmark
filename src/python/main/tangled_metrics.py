"""
This script adds 3 tangled metrics to the metrics file for an experiment.
- Tangled files
- Tangled patch
- Tangled level
"""
import sys
import os

import argparse
import pandas as pd
import numpy as np

from . import metrics
from . import evaluation_results
from pandas.api.types import CategoricalDtype

TANGLED_LEVELS = [
    "tangled_lines",
    "tangled_hunks",
    "tangled_files",
    "tangled_patch",
    "single_concern_patch",
]


def main(metrics_file: str, results_dir: str):
    """
    Implements the script logic.
    """
    df_metrics = evaluation_results.read_metrics(metrics_file)

    # Calculate tangled patch and tangled files metrics.
    ground_truth_files = evaluation_results.retrieve_ground_truth_files(results_dir)
    df_supplemental_metrics = calculate_tangled_metrics(ground_truth_files)

    # Merge the new metrics with the new metrics.
    df_metrics = df_metrics.merge(
        df_supplemental_metrics, on=["project", "commit_id"], how="left"
    )
    if df_metrics.isna().any().any():
        print(
            "Warning: The DataFrame contains NA values. They will be dropped",
            file=sys.stderr,
        )
        print(f"Before {df_metrics.shape}", file=sys.stderr)
        df_metrics = df_metrics.dropna()
        print(f"After {df_metrics.shape}", file=sys.stderr)

    # Add the tangled level metric.
    df_metrics = calculate_tangled_levels(df_metrics)

    print(df_metrics.to_csv(index=False))


def calculate_tangled_metrics(ground_truth_files) -> pd.DataFrame:
    """
    Calculates the tangled metrics for each ground truth file.
    - Tangled patch
    - Tangled file
    Returns a dataframe with the results for each commit.
    """
    data = []
    for file in ground_truth_files:
        if not os.path.exists(file):
            raise FileNotFoundError(f"File {file} does not exist.")

        commit_folder = os.path.basename(os.path.dirname(file))
        project, commit_id = commit_folder.split("_")

        truth_df = evaluation_results.read_ground_truth(file)
        is_tangled_patch = metrics.is_tangled_patch(truth_df)
        tangled_files = metrics.count_tangled_file(truth_df)

        # Add a new row to the dataframe with the results of the current ground truth file. Use df.concat()
        data.append([project, commit_id, is_tangled_patch, tangled_files])

    result_df = pd.DataFrame(
        data, columns=["project", "commit_id", "is_tangled_patch", "tangled_files"]
    )
    result_df["commit_id"] = result_df["commit_id"].astype(str)
    return result_df


def calculate_tangled_levels(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Calculate the tangled level of each commit (row) in the dataframe. The tangled level is the finest level of tangled
    changes a commit has. For example, if a commit has tangled lines, tangled hunk and tangled files,
    the tangled level will be 'tangled lines'.
    The tangled levels are:
    """
    # Set the types of the columns.
    dataframe["is_tangled_patch"] = dataframe["is_tangled_patch"].astype(bool)
    dataframe["tangled_files"] = dataframe["tangled_files"].astype(int)
    dataframe["tangled_lines"] = dataframe["tangled_lines"].astype(int)
    dataframe["single_concern_patch"] = (~dataframe["is_tangled_patch"]).astype(int)
    dataframe["tangled_patch"] = dataframe["is_tangled_patch"].astype(int)

    dataframe["tangled_level"] = None
    # Go through each level from finer granularity to coarser granularity and set the tangled level for each commit if it is not set yet.
    for level in TANGLED_LEVELS:
        dataframe["tangled_level"] = np.where(
            (dataframe[level] > 0) & (dataframe["tangled_level"].isnull()),
            level,
            dataframe["tangled_level"],
        )

    dataframe["tangled_level"] = dataframe["tangled_level"].astype(
        CategoricalDtype(categories=TANGLED_LEVELS, ordered=True)
    )

    return dataframe


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--metrics-file",
        "-m",
        help="CSV file containing the metrics for all commits",
        required=True,
        metavar="METRIC_FILE",
    )

    parser.add_argument(
        "--results-dir",
        "-r",
        help="Path to the directory containing the results for an experiment",
        required=True,
        metavar="RESULTS_DIR",
    )

    args = parser.parse_args()
    main(args.metrics_file, args.results_dir)
