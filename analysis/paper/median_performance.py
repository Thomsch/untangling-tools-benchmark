#!/usr/bin/env python3

"""
Calculates the median decomposition performance of the untangling tools across D4J bugs.
Input: `decomposition_scores.csv` file produced by `score.sh`.
Output: Print the median performance for each untangling tool.
"""
import sys

import pandas as pd


def print_performance(decomposition_file):
    df_performance = pd.read_csv(
        decomposition_file,
        names=[
            "project",
            "bug_id",
            "smartcommit_rand_index",
            "flexeme_rand_index",
            "file_rand_index.csv",
        ],
    )

    # Calculate median performance
    agg_results = df_performance.agg(
        {
            "bug_id": "count",
            "smartcommit_rand_index": "median",
            "flexeme_rand_index": "median",
            "file_rand_index.csv": "median",
        }
    )

    bug_count = int(agg_results["bug_id"])
    smartcommit_median = agg_results["smartcommit_rand_index"]
    flexeme_median = agg_results["flexeme_rand_index"]
    file_rand_index_median = agg_results["file_rand_index.csv"]

    print("% All the data used in the text is one file so that it can be easily updated.")
    print("% Generated automatically by median_performance.py in https://github.com/Thomsch/untangling-tools-benchmark")

    print(f"\\newcommand\\numberOfBugs{{{bug_count}\\xspace}}")
    print(f"\\newcommand\\smartCommitMedian{{{smartcommit_median:.2f}\\xspace}}")
    print(f"\\newcommand\\flexemeMedian{{{flexeme_median:.2f}\\xspace}}")
    print(f"\\newcommand\\fileUntanglingMedian{{{file_rand_index_median:.2f}\\xspace}}")


def main():
    args = sys.argv[1:]

    if len(args) != 1:
        print("Expected 1 argument: <decomposition_scores.csv>")
        exit(-1)

    decomposition_file = args[0]
    print_performance(decomposition_file)


if __name__ == "__main__":
    main()
