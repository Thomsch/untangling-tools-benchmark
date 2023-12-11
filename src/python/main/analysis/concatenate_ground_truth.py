#!/usr/bin/env python3

"""
Concatenates the ground truth CSV files for an experiment into a single CSV file.
"""

import sys
import os

from typing import List

import pandas as pd
import argparse

sys.path.insert(1, os.path.join(sys.path[0], '..'))
import evaluation_results

def main(results_dir: str):
    """
    Implements the script's logic. See module description for details.
    """
    ground_truth_files = retrieve_ground_truth_files(results_dir)

    dfs = []
    for file in ground_truth_files:
        truth_df = evaluation_results.read_ground_truth(file)
        commit_folder = os.path.basename(os.path.dirname(file))
        project, commit_id = commit_folder.split("_")

        truth_df['project'] = project
        truth_df['commit_id'] = commit_id
        dfs.append(truth_df)

    result_df = pd.concat(dfs, ignore_index=True)
    print(result_df.to_csv(index=False))

def retrieve_ground_truth_files(results_dir: str) -> List[str]:
    """
    Retrieves the ground truth files from the given directory.
    """
    ground_truth_files = []
    for root, _, files in os.walk(results_dir):
        for file in files:
            if file == "truth.csv":
                ground_truth_files.append(os.path.join(root, file))

    return ground_truth_files

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "-d",
        "--results-dir",
        help="Path to the directory containing the results for an experiment",
        required=True,
        metavar="RESULTS_DIR",
    )

    args = parser.parse_args()
    main(args.results_dir)