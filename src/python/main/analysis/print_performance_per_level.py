#!/usr/bin/env python3

"""
Prints the mean performance of each tool as a table in latex format on stdout and the commands to reference the values
in the text on stderr.

Arguments:
    --performance-file: A CSV file containing the performance per tool for all datasets.
    --tangled-file: A CSV file containing the tangled metrics for all datasets.
"""

import argparse
import os
import sys

import pandas as pd
import numpy as np

import latex_utils
sys.path.insert(1, os.path.join(sys.path[0], '..'))
import evaluation_results

def main(performance_file:str, metrics_file:str):
    """
    Implements the script logic.
    """
    # Read the files
    performance_df = pd.read_csv(performance_file)
    metrics_df = evaluation_results.read_metrics(metrics_file)

    df = performance_df.merge(metrics_df, how='left', on=['dataset', 'project', 'commit_id'])[['dataset', 'smartcommit_rand_index', 'flexeme_rand_index', 'filename_rand_index', 'tangled_level']]

    # print(df.drop(columns='tangled_level').groupby(['dataset']).mean()) # overall
    df = calculate_performance_per_tangled_level(df)
    df = format_for_latex(df)
    print_performance_table(df)

def calculate_performance_per_tangled_level(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Calculates the mean performance per tangled level.
    """
    dataframe = dataframe.groupby(['dataset', 'tangled_level']).mean()
    return dataframe

def format_for_latex(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Format the latex table with human friendly indices and column names.
    """
    dataframe = dataframe.reset_index() # It's easier to work with flat tidy dataframe.

    # Use human friendly names for the tangled level values
    dataframe['tangled_level'] = dataframe['tangled_level'].replace({
        'tangled_lines': 'Tangled lines',
        'tangled_hunks': 'Tangled hunks',
        'tangled_files': 'Tangled files',
        'tangled_patch': 'Tangled patches',
        'single_concern_patch': 'Single-concern patches',
    })

    # Rename columns
    dataframe = dataframe.rename(columns=latex_utils.TOOL_NAME_MAP)
    dataframe = dataframe.rename(columns={
        'dataset': 'Dataset',
        'tangled_level': 'Tangled level'
    })

    # Set indices
    dataframe = dataframe.set_index(['Dataset', 'Tangled level'])

    # Round data values all at ounce
    dataframe = dataframe.round(latex_utils.PRECISION)

    return dataframe

def print_performance_table(dataframe: pd.DataFrame):
    """
    Prints the dataframe in latex format on stdout.
    """
    print(dataframe.style
          .format(precision=latex_utils.PRECISION).highlight_max(axis=1,props='bfseries: ;')
          .to_latex(multirow_align='t', column_format="llrrr", clines="skip-last;data", hrules=True).replace('nan', 'n/a'))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--performance-file",
        '-p',
        help="CSV file containing the performance per tool for all datasets",
        required=True,
        metavar="PERFORMANCE_FILE",
    )

    parser.add_argument(
        "--metrics-file",
        '-m',
        help="CSV file containing the metrics for all datasets",
        required=True,
        metavar="TANGLED_METRICS_FILE",
    )

    args = parser.parse_args()
    main(args.performance_file, args.metrics_file)
