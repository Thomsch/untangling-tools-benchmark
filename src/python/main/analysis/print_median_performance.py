#!/usr/bin/env python3

"""
Prints the median performance of each untangling tool on stdout in latex format and on stderr as latex commands to reference the values
in the text.

Arguments:
    --d4j: Path to the file the aggregated untangling scores for Defects4J
    --lltc4j: Path to the file the aggregated untangling scores for LLTC4J
"""

import argparse
import os
import sys
from typing import List

import pandas as pd

PRECISION = 2

def print_performance_table(dataframe: pd.DataFrame):
    """
    Prints the dataframe in latex format on stdout.
    """
    print(dataframe.style
          .format(precision=PRECISION).highlight_max(axis=1,props='bfseries: ;')
          .to_latex(multirow_align='t', clines="skip-last;data", hrules=True))


def print_performance_commands(df_performance, aggregator_operation):
    """
    Print the commands to define the performance for each untangling tool on stderr.
    The command names are in the format <dataset><Tool><Aggregator>.

    :param df_performance: The dataframe containing the performance values.
    :param aggregator_operation: The name of the aggregator operation used to calculate the performance.
    """
    for dataset in df_performance.index:
        for tool in df_performance.columns:
            value = df_performance.loc[dataset, tool].round(PRECISION)
            dataset_name_for_latex = dataset.lower().replace('4', 'f')
            tool_name_for_latex = tool.capitalize().replace('-', '')
            aggreator_for_latex = aggregator_operation.capitalize()
            print(f"\\newcommand\\{dataset_name_for_latex}{tool_name_for_latex}{aggreator_for_latex}{{{value}\\xspace}}", file=sys.stderr)


def load_dataframes(*dataset_files: str, names: List[str] = None) -> pd.DataFrame:
    """
    Loads the dataframes from the given files and returns them as a single dataframe.
    If variable names is given, the dataset variables are named accordingly in the returning dataframe.
    """
    if names is None:
        names = [f"{os.path.basename(file)}" for file in dataset_files]

    dataframes = []
    for dataset_file, name in zip(dataset_files, names):
        df = pd.read_csv(dataset_file, names=[
            "project",
            "commit_id",
            "smartcommit_rand_index",
            "flexeme_rand_index",
            "filename_rand_index",
        ],)
        df["dataset"] = name
        dataframes.append(df)

    return pd.concat(dataframes, ignore_index=True)


def clean_labels(dataframe: pd.DataFrame):
    """
    Clean the index and columns names of the dataframe so it's pleasing to read.
    """

    # Rename the index to 'Dataset'
    dataframe.index = dataframe.index.set_names('Dataset')

    # Rename the columns to the tool names in human friendly format.
    dataframe = dataframe.rename(columns={
        "smartcommit_rand_index": "SmartCommit",
        "flexeme_rand_index": "Flexeme",
        "filename_rand_index": "File-based",
    })

    # Reorder the columns
    dataframe = dataframe[["Flexeme", "SmartCommit", "File-based"]]

    return dataframe


def main(d4j_file:str, lltc4j_file:str):
    """
    Implementation of the script's logic. See the script's documentation for details.

    :param d4j_file: Path to the file the aggregated untangling scores for Defects4J
    :param lltc4j_file: Path to the file the aggregated untangling scores for LLTC4J
    """

    # load dataframes
    df_scores = load_dataframes(d4j_file, lltc4j_file, names=["Defects4J", "LLTC4J"])

    # calculate performance
    performance_operator='median'
    df_performance = df_scores.groupby(["dataset"]).agg(
        {
            "smartcommit_rand_index": performance_operator,
            "flexeme_rand_index": performance_operator,
            "filename_rand_index": performance_operator,
        }
    )
    df_performance = clean_labels(df_performance)

    # print performance in latex format
    print_performance_commands(df_performance, performance_operator)
    print_performance_table(df_performance)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--d4j",
        help="Path to the file the aggregated untangling scores for Defects4J",
        required=True,
        metavar="D4J_SCORE_FILE",
    )

    parser.add_argument(
        "--lltc4j",
        help="Path to the file the aggregated untangling scores for LLTC4J",
        required=True,
        metavar="LLTC4J_SCORE_FILE",
    )

    args = parser.parse_args()
    main(args.d4j, args.lltc4j)
