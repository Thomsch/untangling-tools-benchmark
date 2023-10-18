#!/usr/bin/env python3

"""
Collates the all results of the untangling evaluation
(generated by `score.sh` and `clean_decompositions.py`) into a single CSV file.

Output:
A CSV file containing the following columns:
- project: the name of the project
- bug_id: the ID of the Defects4J bug
- treatment: the treatment that classified this line change into <group>
- file: the path to the file
- source: the source line number (for deletions)
- target: the target line number (for insertions)
- group: the group that the file belongs to
"""

import csv
import os
import sys


def main(evaluation_dir):
    """
    Implement the logic of the script. See the module docstring for more
    information.
    """

    # The CSV files generated that we want to collate into a single CSV file.
    # Each filename is mapped to the treatment name that generated it.
    treatment_names = {
        "flexeme_clean.csv": "Flexeme",
        "smartcommit_clean.csv": "SmartCommit",
        "file_untangling.csv": "File Untangling",
        "truth.csv": "Ground Truth",
    }

    print('Project,BugId,Treatment,File,Source,Target,Group')

    # Iterate through each bug directory in the `evaluation` directory of the untangling directory.
    for bug_tag in os.listdir(evaluation_dir):
        bug_dir = os.path.join(evaluation_dir, bug_tag)
        if not os.path.isdir(bug_dir):
            continue

        # Extract project and id from the subdirectory name
        split = bug_tag.split("_")

        if len(split) != 2:
            print(
                f"Invalid subdirectory name: {bug_tag}."
                f" Expected to be of the form <project>_<bug_id>.",
                file=sys.stderr,
            )
            continue

        project, bug_id = split

        # Iterate through each CSV file in the subdirectory
        for csv_filename in os.listdir(bug_dir):
            if csv_filename not in treatment_names.keys():
                continue

            # Open the CSV file and iterate through its rows
            filepath = os.path.join(bug_dir, csv_filename)
            treatment_name = treatment_names.get(csv_filename, csv_filename)
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
        print("usage: combine_decompositions.py <path/to/untangling/evaluation/folder>")
        print("example: combine_decompositions.py untangling-evaluation/evaluation")
        sys.exit(1)

    main(os.path.abspath(args[0]))
