#!/usr/bin/env python3

"""
This script calculates the following 5 commit metrics for a provided D4J bug:
    1. Total number of files updated (i.e. both code and test files)
    2. Number of test files updated
    3. Number of hunks
    4. Average hunk size
    5. Number of lines changed (i.e. all lines with +/- indicators in the original
       diff generated from pre-fix and post-fix versions).

Command Line Args:
    project: D4J Project name
    vid: D4J Bug Id
    out_dir: Path where results are stored
    repo_root: Path where the repo is checked out
Returns:
    The results are stored in a {<project> <id>}.csv file (with 1 row) in <out_dir>/metrics folder.
    CSV header:
    {d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated}
"""

import sys

from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT


def main():
    """
    Implement the logic of the script. See the module docstring for more
    information.
    """
    args = sys.argv[1:]

    if len(args) != 2:
        print("usage: patch | python3 commit_metrics.py <project> <bug_id>")
        sys.exit(1)

    project = args[0]
    vid = args[1]

    patch = PatchSet.from_string(sys.stdin.read())

    files_updated = len(patch)  # The number of files updated
    test_files_updated = 0  # Number of test files updated
    hunks = 0  # Number of hunks
    hunk_sizes = []  # Average size of hunks
    lines_updated = 0  # The number of lines updated in the commit

    for file in patch:
        if file.path.endswith("Test.java"):
            test_files_updated += 1

        for hunk in file:
            hunks += 1
            hunk_sizes.append(len(hunk))
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                lines_updated += 1

    average_hunk_size = sum(hunk_sizes) / len(hunk_sizes)

    print(
        f"{project},{vid},{files_updated},{test_files_updated},"
        f"{hunks},{average_hunk_size},{lines_updated}"
    )


if __name__ == "__main__":
    main()