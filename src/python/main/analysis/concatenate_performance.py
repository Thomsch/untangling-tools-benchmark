#!/usr/bin/env python3

"""
Concatenate the performance of multiple datasets in one CSV file with a header.
The resulting CSV file is printed on stdout.

Arguments:
    --d4j-file: CSV file containing the performance for commits in Defects4J.
    --lltc4j-file: CSV file containing the performance for commits in LLTC4J.
"""

import argparse
import sys
import os

import pandas as pd

sys.path.insert(1, os.path.join(sys.path[0], '..'))
import evaluation_results

def main(d4j_file:str, lltc4j_file:str):
    """
    Implements the script logic.
    """
    # Read the files
    d4j_df = evaluation_results.read_performance(d4j_file, "Defects4J")
    lltc4j_df = evaluation_results.read_performance(lltc4j_file, "LLTC4J")

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
