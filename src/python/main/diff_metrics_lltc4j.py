#!/usr/bin/env python3

"""
This script calculates the following diff metrics for a version control diff file of a Defects4J bug.
The diff file represents of the differences between the source (pre-fix version)
and target (post-fix version) files.
    For unclean VC diff:
    1. Total number of files updated (i.e. both code and test files)
    2. Number of test files updated
    For clean VC diff:
    3. Number of hunks
    4. Average hunk size
    5. Number of code diff lines changed (i.e. all lines with +/- indicators in the original diff)
       If a source code line is modified (not removed or added), this corresponds to 2 diff lines changed.
    6. Number of noncode diff lines changed
    7. Number of tangled lines in a diff file
    8. Number of tangled hunks in a diff file

Command Line Args:
    project: D4J Project name
    vid: D4J Bug Id
    out_dir: Directory where results are stored
    repo_root: Directory where the repo is checked out
Returns:
    The results are stored in a <project>_<id>.csv file (with 1 row) in <out_dir>/metrics folder.
    CSV header:
    {d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated,tangled_hunks_count,tangled_lines_count}
"""
import sys

from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT

from diff_metrics import get_hunks_in_patch, lines_in_patch


def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    args = sys.argv[1:]

    if len(args) != 3:
        print(
            "usage: python3 diff_metrics_lltc4j.py <patch_file> <project_name> <commit_hash>"
        )
        sys.exit(1)

    patch_file = args[0]
    project_name = args[1]
    commit_hash = args[2]

    diff = PatchSet.from_filename(
        patch_file,
        encoding="latin-1",
    )

    # Count the number of changed lines in the unclean VC diff
    all_changed_lines = 0
    test_files_updated = 0
    files_updated = 0  # The number of files updated, not including tests.
    for file in diff:
        if file.path.endswith("Test.java"):
            test_files_updated += 1
        else:
            files_updated += 1
        for hunk in file:
            for line in hunk:
                # A diff line contains an indicator ('+': added to modified
                # program, '-': removed from original program, ' ': unchanged
                # from original to modified program) and a line value (i.e. the
                # textual content of the source code line).
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                all_changed_lines += 1

    # Generate diff metrics on clean VC diff
    hunks_count = len(get_hunks_in_patch(diff))
    code_changed_lines = len(lines_in_patch(diff))
    average_hunk_size = (code_changed_lines / hunks_count) if hunks_count != 0 else ""

    print(
        f"{project_name},{commit_hash},{files_updated},{test_files_updated},"
        f"{hunks_count},{average_hunk_size},{code_changed_lines},{all_changed_lines - code_changed_lines},"
        f"0,0"  # TODO: No tangled lines/hunks for now. Used to be tangle_counts(repository_path)
    )


if __name__ == "__main__":
    main()
