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
import os

import pandas as pd


def read_dataset_file(file:str, name:str):
    df = pd.read_csv(file, header=0)
    df['dataset'] = name
    return df

def main(d4j_file:str, lltc4j_file:str):
    """
    Implements the script logic.
    """
    # Read the files
    d4j_df = read_dataset_file(d4j_file, "Defects4J")
    lltc4j_df = read_dataset_file(lltc4j_file, "LLTC4J")

    result_df = pd.concat([d4j_df, lltc4j_df], ignore_index=True)
    print(result_df.to_csv(index=False))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--d4j",
        help="File containing the line counts for Defects4J",
        required=True,
        metavar="D4J_FILE",
    )

    parser.add_argument(
        "--lltc4j",
        help="File containing the line counts for LLTC4J",
        required=True,
        metavar="LLTC4J_FILE",
    )

    args = parser.parse_args()
    main(args.d4j, args.lltc4j)
