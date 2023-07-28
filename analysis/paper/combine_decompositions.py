#!/usr/bin/env python3

"""
Collates the results of the benchmark evaluation from flexeme.csv,
smartcommit.csv, and file_untangling.csv into a single CSV file containing
the following columns:
- project: the name of the project
- bug_id: the ID of the Defects4J bug
- treatment: the treatment that classified this line change into <group>
- file: the path to the file
- source: the source line number (for deletions)
- target: the target line number (for insertions)
- group: the group that the file belongs to

Outputs the CSV file to stdout.
"""

import csv
import os
import sys


def main(evaluation_dir):
    """
    Implement the logic of the script. See the module docstring for more
    information.
    """
    result_files = [
        "flexeme_clean.csv",
        "smartcommit_clean.csv",
        "file_untangling.csv",
        "truth_all.csv",
    ]

    pretty_names = {
        "flexeme_clean.csv": "Flexeme",
        "smartcommit_clean.csv": "SmartCommit",
        "file_untangling.csv": "File Untangling",
        "truth_all.csv": "Ground Truth",
    }

    print('Project,BugId,Treatment,File,Source,Target,Group')

    # Iterate through each subdirectory in the parent directory
    for subdir in os.listdir(evaluation_dir):
        subdir_path = os.path.join(evaluation_dir, subdir)
        if not os.path.isdir(subdir_path):
            continue

        # Extract project and id from the subdirectory name
        split = subdir.split("_")

        if len(split) != 2:
            print(
                f"Invalid subdirectory name: {subdir}."
                f" Expected to be of the form <project>_<bug_id>",
                file=sys.stderr,
            )
            continue

        project, bug_id = split

        # Iterate through each CSV file in the subdirectory
        for filename in os.listdir(subdir_path):
            if filename not in result_files:
                continue

            # Open the CSV file and iterate through its rows
            filepath = os.path.join(subdir_path, filename)

            treatment_name = pretty_names.get(filename, filename)

            with open(filepath, "r") as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    print(
                        f"{project},{bug_id},{treatment_name},"
                        f"{row['file']},{row['source']},{row['target']},{row['group']}"
                    )


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: combine_decompositions.py <path/to/benchmark/evaluation/folder>")
        sys.exit(1)

    main(os.path.abspath(args[0]))