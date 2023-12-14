#!/usr/bin/env python3

"""
Concatenate Defects4J and LLTC4J CSV files into one CSV file.
The resulting CSV file is printed on stdout.

Arguments:
    --d4j-file: CSV file for Defects4J.
    --lltc4j-file: CSV file for LLTC4J.
"""

import argparse
import sys

import pandas as pd

from . import latex_utils

def main(file:str):
    """
    Implements the script logic.
    """
    df = pd.read_csv(file, header=0)

    # Calculate missing lines
    df['missingline'] = df['truth_lines'] - df['tool_lines']

    # Calculate percentage of missing lines
    df['percentage'] = df['missingline'] / df['truth_lines']

    # Calculate the sum of missing lines and truth lines
    total_missing_lines = df['missingline'].sum()
    total_truth_lines = df['truth_lines'].sum()

    # Calculate the overall missing lines percentage
    overall_percentage = total_missing_lines / total_truth_lines

    # Calculate the mean of the percentage column
    mean_percentage = df['percentage'].mean()

    mean_per_dataset = df.groupby('dataset')['percentage'].mean().reset_index()


    # Print results
    print_latex_value('Total missing lines:', total_missing_lines)
    print_latex_value('Total truth lines:', total_truth_lines)
    print_latex_value('Total missing lines percentage:', overall_percentage.round(latex_utils.PRECISION))

    for index, row in mean_per_dataset.iterrows():
        print_latex_value(f"Mean missing lines percentage {row['dataset']}", round(row['percentage'], latex_utils.PRECISION))

    print_latex_value('Mean missing lines percentage:', mean_percentage.round(latex_utils.PRECISION))


def print_latex_value(label: str, value:str):
    """
    Print a comment that is human readable and command for the value.
    """
    formatted_value = '{:.0%}'.format(value) if 'percentage' in label else value
    print(f"% {label}: {formatted_value}")
    print(format_latex_command(label, formatted_value))
    print()

def format_latex_command(label: str, value:str) -> str:
    """
    Format a latex command to be valid.
    """
    command_name = label.split()
    command_name = [name.capitalize() for name in command_name]
    command_name[0] = command_name[0].lower()
    command_name = "".join(command_name)

    latex_value = str(value).replace("%","\%")
    return f"\\newcommand\\{command_name}{{{latex_value}\\xspace}}"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--counts",
        '-c',
        help="CSV file containing the untangled line counts for all datasets",
        required=True,
        metavar="FILE",
    )

    args = parser.parse_args()
    main(args.counts)
