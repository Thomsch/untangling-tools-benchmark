#!/usr/bin/env python3

"""
Print a summary of the number of groups per commit for each tool for each dataset.
"""

import argparse
import os
import sys
from typing import Dict, List

import pandas as pd

from concatenate_untangled_lines import concatenate_untangled_lines_for_dataset, column_names_dataset


def order_rows_by_treatment(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Orders the rows of the given dataframe based on the order of the 'treatment' index.
    Expects the dataframe to contain a 'treatment' index.

    Arguments:
        dataframe: The dataframe to order by 'treatment'.
    """
    assert 'treatment' in dataframe.index.names

    treatment_order = ['truth', 'flexeme', 'smartcommit', 'filename']

    # Remove 'treatment' from the index and convert it to a column
    dataframe.reset_index(level='treatment', inplace=True)

    # Convert 'treatment' to a categorical variable with the specified order
    dataframe['treatment'] = pd.Categorical(dataframe['treatment'], categories=treatment_order, ordered=True)

    # Set 'treatment' back as an index
    dataframe.set_index('treatment', append=True, inplace=True)

    # Sort the DataFrame based on the order of the indices
    dataframe.sort_index(inplace=True)
    return dataframe


def prettify_summary(df : pd.DataFrame) -> pd.DataFrame:
    """
    Prettifies the given summary dataframe. Specifically:
    - Order rows by treatment
    - Captialize treatment names (truth, flexeme, smartcommit, filename) -> (Truth, Flexeme, Smartcommit, Filename)
    - Rename index 'Filename' into 'File-based'
    - Capitalize indexes names (treatment, dataset) -> (Treatment, Dataset)
    - Rename column Std_dev into Std. dev.
    """
    df = order_rows_by_treatment(df)

    # Capitalize treatment names
    df.index = df.index.set_levels(df.index.levels[1].str.capitalize(), level='treatment')

    # Rename index 'Filename' into 'File-based'
    df = df.rename_axis(index={'filename': 'File-based'})

    # Rename index 'Truth' into 'Ground truth'
    df = df.rename_axis(index={'truth': 'Ground truth'})

    # Rename column Std_dev into Std. dev.
    df = df.rename(columns={'min': 'Min'})
    df = df.rename(columns={'max': 'Max'})
    df = df.rename(columns={'median': 'Median'})
    df = df.rename(columns={'std': 'Std. dev.'})

    # Rename column 'dataset' into 'Dataset'
    df = df.rename_axis(index={'dataset': 'Dataset'})

    # Rename column 'treatment' into 'Treatment'
    df = df.rename_axis(index={'treatment': 'Treatment'})

    return df

def concatenate_datasets(dataset_dirs: List[str], dataset_name_map: Dict[str, str]) -> pd.DataFrame:
    """
    Concatenates the datasets in the given directories into a single dataframe.

    Arguments:
        dataset_dirs: The directories containing the datasets.
        dataset_name_map: A mapping from the dataset directories to the dataset names to use in the dataframe.
    """
    column_names_evaluation = ["dataset"] + column_names_dataset
    result_df = pd.DataFrame(columns=column_names_evaluation)

    for dataset_dir in dataset_dirs:
        if dataset_dir is None:
            continue

        evaluation_path = os.path.join(dataset_dir, "evaluation")
        if not os.path.exists(evaluation_path):
            raise ValueError(f"Directory {evaluation_path} does not exist.")

        untangled_lines_dataset_df = concatenate_untangled_lines_for_dataset(evaluation_path)
        untangled_lines_dataset_df["dataset"] = dataset_name_map[dataset_dir]
        result_df = pd.concat([result_df, untangled_lines_dataset_df], ignore_index=True)

    return result_df

def main(args: argparse.Namespace):
    """
    Implementation of the script's logic. See the script's documentation for details.
    """
    dataset_name_map = {args.d4j: "Defects4J", args.lltc4j: "LLTC4J"}
    concatenated_df = concatenate_datasets([args.d4j, args.lltc4j], dataset_name_map)

    # Calculate the number of distinct groups per tool in each commit.
    group_count_df = concatenated_df.groupby(['dataset', 'project', 'bug_id', 'treatment']).agg(group_count=('group', 'nunique'))

    # Calculate summary statistics per treatment in each dataset.
    summary_df = group_count_df.groupby(['dataset', 'treatment']).agg(['min', 'max', 'median', 'std'])

    summary_df = prettify_summary(summary_df)
    print(summary_df.style
          .format(precision=0)
          .to_latex(multirow_align='t', clines="skip-last;data", hrules=True))

def create_arg_parser() -> argparse.ArgumentParser:
    """
    Creates the argument parser for scripts expecting multiple datasets.
    """
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--d4j",
        help="Folder containing the untangling results of D4J",
        metavar="PATH",
    )

    parser.add_argument(
        "--lltc4j",
        help="Folder containing the untangling results of LLTC4J",
        metavar="PATH",
    )

    return parser


if __name__ == "__main__":
    main_parser = create_arg_parser()
    args = main_parser.parse_args()
    main(args)