#!/usr/bin/env python3

"""
This script counts the missing result files in the evaluation. i.e.:
    - flexeme.csv
    - smartcommit.csv
    - scores.csv
    - truth.csv
    - file_untangling.csv

This script prints the following on the standard output:
- Total number of bug result folders existing in the evaluation directory.
- Total number of bug result folders with missing files (i.e., bug results that are missing at least one result file)
- Number of times each result file is missing.
- List of bug result folders and the missing files in each folder. i.e.:
    - <bug folder>: <missing_file_1>, <missing_file_2>, ..
"""

import os
import sys
from collections import defaultdict


def main(evaluation_dir):
    """
    Implement the logic of the script. See the module docstring.
    """
    required_files = {
        "flexeme.csv",
        "smartcommit.csv",
        "scores.csv",
        "truth.csv",
        "file_untangling.csv"
    }
    missing_files = []
    bug_folder_missing_files = defaultdict(int)
    bug_folder_counter = 0

    # Walk through the directory tree starting from 'evaluation'
    for root, dirs, files in os.walk(evaluation_dir):
        bug_name = os.path.basename(root)
        # Check if the current directory is a bug_name folder
        if root != "evaluation" and len(files) > 0:
            # Check if all the required CSV files are present in the bug_name folder
            missing_files_for_project = required_files - set(files)
            bug_folder_counter += 1
            if missing_files_for_project:
                missing_files.append(
                    (bug_name, list(missing_files_for_project))
                )
                bug_folder_missing_files[bug_name] += len(
                    missing_files_for_project
                )

    # Print the list of projects and missing files
    print(f"Total number of bug folder visited: {bug_folder_counter}")
    print(f"Total number of bug folder with missing files: {len(missing_files)}")
    print("Number of times each file is missing:")
    for required_file in required_files:
        count = sum(
            1
            for project_missing in missing_files
            if required_file in project_missing[1]
        )
        print(f"{required_file}: {count}")
    print("The following bug folders are missing the following files:")
    for bug_name, missing in missing_files:
        print(f'{bug_name}: {", ".join(missing)}')


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: count_missing_results.py <path/to/evaluation/root>")
        sys.exit(1)

    evaluation_root = os.path.abspath(args[0])
    evaluation_dir = os.path.join(evaluation_root, "evaluation")
    main(evaluation_dir)
