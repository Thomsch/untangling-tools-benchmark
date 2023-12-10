#!/usr/bin/env python3

"""
Prints the median performance of each untangling tool on stdout in latex format and on stderr as latex commands to reference the values
in the text.
If the --overall flag is given, the overall performance is calculated, only the commands are generated on stdout. Not table is printed.

Arguments:
    --d4j: Path to the file the aggregated untangling scores for Defects4J
    --lltc4j: Path to the file the aggregated untangling scores for LLTC4J
    --aggregator: The aggregator operation used to calculate the performance. e.g., median, mean
    --overall: Whether to calculate the overall performance or per dataset.
"""

import argparse
import os
import sys
from typing import List

import pandas as pd

PRECISION = 2

TOOL_NAME_MAP = {
    "smartcommit_rand_index": "SmartCommit",
    "flexeme_rand_index": "Flexeme",
    "filename_rand_index": "File-based",
}
def main(d4j_file:str, lltc4j_file:str, aggregator:str, overall:bool):
    """
    Implementation of the script's logic. See the script's documentation for details.

    :param d4j_file: Path to the file the aggregated untangling scores for Defects4J
    :param lltc4j_file: Path to the file the aggregated untangling scores for LLTC4J
    """

    # load dataframes
    df_scores = load_dataframes(d4j_file, lltc4j_file, names=["Defects4J", "LLTC4J"])

    aggregator_config = {
        "smartcommit_rand_index": aggregator,
        "flexeme_rand_index": aggregator,
        "filename_rand_index": aggregator,
    }

    if overall:
        df_performance = df_scores.agg(aggregator_config).reset_index()
        print_overall_performance_commands(df_performance, aggregator)
    else:
        # calculate performance
        df_performance = df_scores.groupby(["dataset"]).agg(aggregator_config)

        df_performance = clean_labels(df_performance)
        print_performance_table(df_performance)
        print_performance_commands(df_performance, aggregator)


def print_performance_table(dataframe: pd.DataFrame):
    """
    Prints the dataframe in latex format on stdout.
    """
    print(dataframe.style
          .format(precision=PRECISION).highlight_max(axis=1,props='bfseries: ;')
          .to_latex(multirow_align='t', clines="skip-last;data", hrules=True))

def print_overall_performance_commands(dataframe, aggregator):
    dataframe.columns = ['tool', 'value']
    dataframe = dataframe.replace(TOOL_NAME_MAP)
    dataframe['value'] = dataframe['value'].round(PRECISION)

    for index, row in dataframe.iterrows():
        tool_name_for_latex = row['tool'].capitalize().replace('-', '')
        aggreator_for_latex = aggregator.capitalize()
        print(f"\\newcommand\\overall{tool_name_for_latex}{aggreator_for_latex}{{{row['value']}\\xspace}}")


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
    dataframe = dataframe.rename(columns=TOOL_NAME_MAP)

    # Reorder the columns
    dataframe = dataframe[["Flexeme", "SmartCommit", "File-based"]]

    return dataframe

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

    parser.add_argument(
        "--aggregator",
        help="The aggregator operation used to calculate the performance. e.g., median, mean",
        required=True,
        metavar="AGGREGATOR",
    )

    parser.add_argument(
        "--overall",
        help="Whether to calculate the overall performance or per dataset.",
        required=False,
        default=False,
        metavar="OVERALL",
    )

    args = parser.parse_args()
    main(args.d4j, args.lltc4j, args.aggregator, args.overall)
