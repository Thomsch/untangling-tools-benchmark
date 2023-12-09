"""
Prints the number of tangled changes for each the tangled levels.
There are 5 tangles levels:
- Tangled line: a tangled line exists
- Tangled hunk: no tangled line exists, but a tangled hunk exists
- Tangled file: no tangled hunk exists, but a tangled file exists
- Tangled patch: no tangled file exists, but the change is still tangled
- Single-concern patch: the change is not tangled
"""

import argparse
import os
import sys
from typing import List

import pandas as pd
import numpy as np
from pandas.api.types import CategoricalDtype

sys.path.insert(1, os.path.join(sys.path[0], '..'))

import tangled_metrics as tangled_metrics

def main(d4j_metrics_file: str, d4j_result_dir, lltc4j_metrics_file: str, lltc4j_result_dir: str):
    """
    Implement the logic of the script. See the module docstring.
    """
    df_tangled_metrics_d4j = assemble_tangled_metrics(d4j_metrics_file, d4j_result_dir, "Defects4J")
    df_tangled_metrics_lltc4j = assemble_tangled_metrics(lltc4j_metrics_file, lltc4j_result_dir, "LLTC4J")
    df_tangled_metrics = pd.concat([df_tangled_metrics_d4j, df_tangled_metrics_lltc4j], ignore_index=True)

    df_tangled_metrics_aggregated = count_tangled_levels(df_tangled_metrics, True)

    df = format_for_latex(df_tangled_metrics_aggregated)
    print_to_latex(df)



def assemble_tangled_metrics(commit_metrics_file: str, results_dir: str, dataset: str) -> pd.DataFrame:
    """
    Assembles the tangled metrics for each commit in the given commit metrics file.
    And calculates new metrics with the ground truth files in the given directory.
    """
    df_metrics = pd.read_csv(commit_metrics_file)
    df_supplemental_metrics = calculate_tangled_metrics(retrieve_ground_truth_files(results_dir))

    # Convert the commit_id column to string
    df_metrics['vid'] = df_metrics['vid'].astype(str)
    df_supplemental_metrics['commit_id'] = df_supplemental_metrics['commit_id'].astype(str)

    # Merge the new metrics with the commit metrics.
    df_metrics = df_metrics.merge(df_supplemental_metrics, left_on=['project', 'vid'], right_on=['project', 'commit_id'], how='left')

    if df_metrics.isna().any().any():
        print("Warning: The DataFrame contains NA values. They will be dropped", file=sys.stderr)
        print(df_metrics.to_string(), file=sys.stderr)  # Optionally, you can print the locations of NaN values in the DataFrame
        # drop rows with NaN values
        print(f"Before {df_metrics.shape}", file=sys.stderr)
        df_metrics = df_metrics.dropna()
        print(f"After {df_metrics.shape}", file=sys.stderr)


    df_metrics['is_tangled_patch'] = df_metrics['is_tangled_patch'].astype(bool)
    df_metrics['tangled_files_count'] = df_metrics['tangled_files_count'].astype(int)
    df_metrics['tangled_lines'] = df_metrics['tangled_lines'].astype(int)

    df_metrics = df_metrics.drop(columns=['commit_id', 'files_updated', 'hunks', 'average_hunk_size', 'code_changed_lines'])
    df_metrics['dataset'] = dataset
    return df_metrics

def count_tangled_levels(df: pd.DataFrame, exclusive_levels=False) -> pd.DataFrame:
    """
    Count the number of commits that have tangled metrics. Returns a dataframe in a tidy format with columns 'dataset', 'tangled_metric' and 'count'.
    If exclusive_levels is true, only lowest granularity level is counted.
    For example, if a commit has tangled lines, tangled hunk and tangled files, it will only be counted as tangled lines.
    """
    # Drop 'project' column, if it exists. We are not using it.
    result_df = df.copy()
    if "project" in result_df.columns:
        result_df = result_df.drop(columns=["project"])

    result_df['single_concern_patch'] = (~result_df['is_tangled_patch']).astype(int)
    result_df['tangled_patch'] = result_df['is_tangled_patch'].astype(int)
    result_df = result_df.drop(columns=["is_tangled_patch", 'vid'])

    levels = ['tangled_lines', 'tangled_hunks', 'tangled_files_count', 'tangled_patch', 'single_concern_patch']
    if exclusive_levels:
        result_df['tangled_level'] = None

        # Go through each level from finer granularity to coarser granularity and set the tangled level for each commit if it is not set yet.
        for level in levels:
            result_df['tangled_level'] = np.where((result_df[level] > 0) & (result_df['tangled_level'].isnull()), level, result_df['tangled_level'])

        result_df['tangled_level'] = result_df['tangled_level'].astype(CategoricalDtype(categories=levels, ordered=True))
        result_df = result_df.groupby('dataset')['tangled_level'].value_counts(sort=False).reset_index()
        result_df = result_df.rename(columns={'tangled_level': 'tangled_metric'})
    else:
        result_df = result_df.groupby('dataset').agg(lambda x: np.count_nonzero(x))
        result_df = result_df.reset_index().melt(id_vars=['dataset']).rename(columns={'variable': 'tangled_metric', 'value': 'count'})

    result_df['tangled_metric'] = result_df['tangled_metric'].astype(CategoricalDtype(categories=levels, ordered=True))

    return result_df.sort_values(by=['dataset', 'tangled_metric'])

def calculate_tangled_metrics(ground_truth_files) -> pd.DataFrame:
    """
    Calculates the tangled metrics for each ground truth file.
    Returns a dataframe with the results for each commit.
    """
    data = []
    for file in ground_truth_files:
        if not os.path.exists(file):
            raise FileNotFoundError(f"File {file} does not exist.")

        commit_folder = os.path.basename(os.path.dirname(file))
        project, commit_id = commit_folder.split("_")

        truth_df = tangled_metrics.read_ground_truth(file)
        is_tangled_patch = tangled_metrics.is_tangled_patch(truth_df)
        tangled_files = tangled_metrics.count_tangled_file(truth_df)

        # Add a new row to the dataframe with the results of the current ground truth file. Use df.concat()
        data.append([project, commit_id, is_tangled_patch, tangled_files])

    result_df = pd.DataFrame(data, columns=['project', 'commit_id', 'is_tangled_patch', 'tangled_files_count'])
    return result_df


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

def format_for_latex(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Formats the dataframe so it can be printed to latex.
    - Reshape the dataframe
    - Use human friendly names for the indices, columns and values
    """
    # Reshape the dataframe
    dataframe = dataframe.pivot(columns='dataset', index='tangled_metric',values='count').reset_index().rename_axis(None, axis=1)

    # Use human friendly names for the tangled metrics values
    dataframe['tangled_metric'] = dataframe['tangled_metric'].replace({
        'tangled_lines': 'Tangled lines',
        'tangled_hunks': 'Tangled hunks',
        'tangled_files_count': 'Tangled files',
        'tangled_patch': 'Tangled patches',
        'single_concern_patch': 'Single-concern patches',
    })

    # Set the index to be tangled_metric and rename it to 'Tangled metric'
    dataframe = dataframe.set_index('tangled_metric')
    dataframe.index.name = 'Tangled metric'

    return dataframe


def print_to_latex(dataframe: pd.DataFrame):
    print(dataframe.style.to_latex(multirow_align='t', clines="skip-last;data", hrules=True))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--d4j-metrics",
        help="Path to the file the metrics for all Defects4J commits",
        required=True,
        metavar="D4J_METRIC_FILE",
    )

    parser.add_argument(
        "--d4j-results",
        help="Path to the directory containing the results for Defects4J",
        required=True,
        metavar="D4J_RESULTS_DIR",
    )

    parser.add_argument(
        "--lltc4j-metrics",
        help="Path to the file the metrics for all LLTC4J commits",
        required=True,
        metavar="LLTC4J_,METRIC_FILE",
    )

    parser.add_argument(
        "--lltc4j-results",
        help="Path to the directory containing the results for LLTC4J",
        required=True,
        metavar="LLTC4J_RESULTS_DIR",
    )

    args = parser.parse_args()
    main(args.d4j_metrics, args.d4j_results, args.lltc4j_metrics, args.lltc4j_results)
