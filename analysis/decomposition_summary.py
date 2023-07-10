#!/usr/bin/env python3

"""
This script lists missing tool decompositions in the evaluation for each bug.
Input: the path to the evaluation foot folder.
Output: a row for each bug in the evaluation, with the following columns:
    - project: the name of the project
    - bug_id: the id of the bug
    - flexeme_exists: true if flexeme decomposition is present, false otherwise
    - smartcommit_exists: true if smartcommit decomposition is present, false otherwise
"""

import os
import sys


def main(path):
    """
    Implement the logic of the script. See the module docstring for more
    information.
    """
    print("project,bug_id,flexeme_exists,smartcommit_exists")

    # Walk through the directory tree starting from 'evaluation'
    for root, _, _ in os.walk(path):
        if root == path:
            continue

        split = root.split("_")

        if len(split) != 2:
            print(
                f"Invalid subdirectory name: {root}. Expected to be of the form <project>_<bug_id>",
                file=sys.stderr,
            )
            continue

        project, bug_id = split

        flexeme_exists = os.path.exists(os.path.join(root, "flexeme.csv"))
        smartcommit_exists = os.path.exists(os.path.join(root, "smartcommit.csv"))

        print(
            f"{os.path.basename(project)},{bug_id},{flexeme_exists},{smartcommit_exists}"
        )


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: decomposition_summary.py <path/to/evaluation/folder>")
        sys.exit(1)

    main(os.path.abspath(args[0]))
