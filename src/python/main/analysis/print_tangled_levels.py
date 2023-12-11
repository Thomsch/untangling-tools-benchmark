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

import tangled_metrics
import evaluation_results

def main(d4j_metrics_file: str, lltc4j_metrics_file: str):
    """
    Implement the logic of the script. See the module docstring.
    """
    df_tangled_metrics_d4j = evaluation_results.read_metrics(d4j_metrics_file, "Defects4J")
    df_tangled_metrics_lltc4j = evaluation_results.read_metrics(lltc4j_metrics_file, "LLTC4J")

    df_tangled_metrics = pd.concat([df_tangled_metrics_d4j, df_tangled_metrics_lltc4j], ignore_index=True)
    df_tangled_metrics = df_tangled_metrics[['dataset', 'tangled_levels']] # Drop unused columns

    df_tangled_metrics = df_tangled_metrics.groupby('dataset').value_counts(sort=False, normalize=True).reset_index(name='count')
    df_tangled_metrics['tangled_level'] = df_tangled_metrics['tangled_level'].astype(CategoricalDtype(categories=tangled_metrics.TANGLED_LEVELS, ordered=True))
    df_tangled_metrics =  df_tangled_metrics.sort_values(by=['dataset', 'tangled_level'])

    df = format_for_latex(df_tangled_metrics)
    print_to_latex(df)


def format_for_latex(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Formats the dataframe so it can be printed to latex.
    - Reshape the dataframe
    - Use human friendly names for the indices, columns and values
    """

    # Format 'count' column to be a percentage
    dataframe['count'] = dataframe['count'].map(lambda x: f"{x:.0%}")

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
        "--lltc4j-metrics",
        help="Path to the file the metrics for all LLTC4J commits",
        required=True,
        metavar="LLTC4J_,METRIC_FILE",
    )

    args = parser.parse_args()
    main(args.d4j_metrics, args.lltc4j_metrics)
