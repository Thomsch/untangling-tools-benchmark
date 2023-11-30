#!/usr/bin/env python3

"""
Print a summary of the number of groups per commit for each tool for each dataset.
"""

import argparse
import os
import sys

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


def prettify_summary(summary_df : pd.DataFrame) -> pd.DataFrame:
    """
    Prettifies the given summary dataframe. Specifically:
    - Order rows by treatment
    - Captialize treatment names (truth, flexeme, smartcommit, filename) -> (Truth, Flexeme, Smartcommit, Filename)
    - Capitalize indexes names (treatment, dataset) -> (Treatment, Dataset)
    - Rename column Std_dev into Std. dev.
    """
    summary_df = order_rows_by_treatment(summary_df)

    summary_df.index = summary_df.index.set_levels(summary_df.index.levels[1].str.capitalize(), level='treatment')

    # Rename column Std_dev into Std. dev.
    summary_df = summary_df.rename(columns={'min': 'Min'})
    summary_df = summary_df.rename(columns={'max': 'Max'})
    summary_df = summary_df.rename(columns={'median': 'Median'})
    summary_df = summary_df.rename(columns={'std': 'Std. dev.'})

    # Rename column 'dataset' into 'Dataset'
    summary_df = summary_df.rename_axis(index={'dataset': 'Dataset'})

    # Rename column 'treatment' into 'Treatment'
    summary_df = summary_df.rename_axis(index={'treatment': 'Treatment'})

    return summary_df


if __name__ == "__main__":
    main_parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    main_parser.add_argument(
        "--d4j",
        help="Folder containing the untangling results of D4J",
        metavar="PATH",
    )

    main_parser.add_argument(
        "--lltc4j",
        help="Folder containing the untangling results of LLTC4J",
        metavar="PATH",
    )

    args = main_parser.parse_args()

    dataset_name_map = {args.d4j: "Defects4J", args.lltc4j: "LLTC4J"}

    column_names_evaluation = ["dataset"] + column_names_dataset
    concatenate_df = pd.DataFrame(columns=column_names_evaluation)

    for dataset in [args.d4j, args.lltc4j]:
        if dataset is None:
            continue

        evaluation_path = os.path.join(dataset, "evaluation")
        if not os.path.exists(evaluation_path):
            raise ValueError(f"Directory {evaluation_path} does not exist.")

        untangled_lines_dataset_df = concatenate_untangled_lines_for_dataset(evaluation_path)
        untangled_lines_dataset_df["dataset"] = dataset_name_map[dataset]
        concatenate_df = pd.concat([concatenate_df, untangled_lines_dataset_df], ignore_index=True)

    # Calculate the number of distinct groups per tool in each commit.
    group_count = concatenate_df.groupby(['dataset', 'project', 'bug_id', 'treatment']).agg(group_count=('group', 'nunique'))

    # Calculate summary statistics per treatment in each dataset.
    summary = group_count.groupby(['dataset', 'treatment']).agg(['min', 'max', 'median', 'std'])

    summary = prettify_summary(summary)
    print(summary.style
          .format(precision=0)
          .to_latex(multirow_align='t', clines="skip-last;data", hrules=True))
