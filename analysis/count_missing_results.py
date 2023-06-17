#!/usr/bin/env python3
import os
import sys
from collections import defaultdict


#
# This script counts the number of projects with missing results in the benchmark.
#
def main(path):
    required_files = [
        "flexeme.csv",
        "smartcommit.csv",
        "scores.csv",
        "truth.csv",
        "file_untangling.csv",
    ]
    missing_files = []
    projects_missing_files = defaultdict(int)
    project_counter = 0

    # Walk through the directory tree starting from 'evaluation'
    for root, dirs, files in os.walk(path):
        # Check if the current directory is a project folder
        if root != "evaluation" and len(files) > 0:
            # Check if all the required CSV files are present in the project folder
            missing = set(required_files) - set(files)
            project_counter += 1
            if missing:
                missing_files.append((os.path.basename(root), list(missing)))
                projects_missing_files[os.path.basename(root)] += len(missing)

    # Print the list of projects and missing files
    print(f"Total number of projects visited: {project_counter}")
    print(f"Total number of projects with missing files: {len(missing_files)}")
    print("Number of times each file is missing:")
    for file in required_files:
        count = sum(
            [1 for project_missing in missing_files if file in project_missing[1]]
        )
        print(f"{file}: {count}")
    print("The following projects are missing the following files:")
    for project, missing in missing_files:
        print(f'{project}: {", ".join(missing)}')


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: count_missing_results.py <path/to/benchmark/root>")
        exit(1)

    benchmark_root = os.path.abspath(args[0])
    path = os.path.join(benchmark_root, "evaluation")
    main(path)
