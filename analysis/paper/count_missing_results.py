#!/usr/bin/env python3

"""
This script counts the missing result files in the evaluation.

This script prints the following on the standard output:
- Total number of projects visited
- Total number of projects with missing files (i.e., projects that are missing at least one of the required files)
- Number of times each untangling result file is missing:
    - flexeme.csv
    - smartcommit.csv
    - scores.csv
    - truth.csv
    - file_untangling.csv
- The following projects are missing the following files:
    - <project_name>: <missing_file_1>, <missing_file_2>, ..
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
    projects_missing_files = defaultdict(int)
    project_counter = 0

    # Walk through the directory tree starting from 'evaluation'
    for root, dirs, files in os.walk(evaluation_dir):
        # Check if the current directory is a project folder
        if root != "evaluation" and len(files) > 0:
            # Check if all the required CSV files are present in the project folder
            missing_files_for_project = required_files - set(files)
            project_counter += 1
            if missing_files_for_project:
                missing_files.append(
                    (os.path.basename(root), list(missing_files_for_project))
                )
                projects_missing_files[os.path.basename(root)] += len(
                    missing_files_for_project
                )

    # Print the list of projects and missing files
    print(f"Total number of projects visited: {project_counter}")
    print(f"Total number of projects with missing files: {len(missing_files)}")
    print("Number of times each file is missing:")
    for required_file in required_files:
        count = sum(
            1
            for project_missing in missing_files
            if required_file in project_missing[1]
        )
        print(f"{required_file}: {count}")
    print("The following projects are missing the following files:")
    for project, missing in missing_files:
        print(f'{project}: {", ".join(missing)}')


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: count_missing_results.py <path/to/evaluation/root>")
        sys.exit(1)

    evaluation_root = os.path.abspath(args[0])
    evaluation_dir = os.path.join(evaluation_root, "evaluation")
    main(evaluation_dir)
