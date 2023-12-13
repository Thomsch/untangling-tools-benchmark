"""
Count the clustered lines saved in FILE_NAME and in the associated ground truth
for the commits in the dataset.

Outputs a CSV file with header specified by COLUMNS.
"""

import sys
import argparse
import os

import pandas as pd

from .. import evaluation_results

FILE_NAME="flexeme.csv"
COLUMNS = ['project', 'commit_id', 'tool_lines', 'truth_lines']

def main(directory:str):
    ground_truth_files = evaluation_results.retrieve_ground_truth_files(directory)

    data = []
    for truth_file in ground_truth_files:
        truth_df = evaluation_results.read_ground_truth(truth_file)

        commit_folder = os.path.basename(os.path.dirname(truth_file))
        project, commit_id = commit_folder.split("_")

        flexeme_file = os.path.join(commit_folder, FILE_NAME)

        if os.path.exists(flexeme_file):
            flexeme_df = evaluation_results.read_tool_untangling(flexeme_file)
            flexeme_df = flexeme_df.drop_duplicates(subset=["file", "source", "target"])
        else:
            flexeme_df = pd.DataFrame(columns=evaluation_results.GROUND_TRUTH_COLUMNS)

        data.append([project, commit_id, len(flexeme_df), len(truth_df)])

    result_df = pd.DataFrame(data, columns=COLUMNS)
    result_df["commit_id"] = result_df["commit_id"].astype(str)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--directory",
        help="Path to the directory containing the ground truth files",
        required=True,
        metavar="DIRECTORY",
    )

    args = parser.parse_args()
    main(args.directory)
