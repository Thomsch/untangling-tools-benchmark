#!/usr/bin/env python3

"""
This script calculates the following 7 commit metrics for a provided D4J bug:
    1. Total number of files updated (i.e. both code and test files)
    2. Number of test files updated
    3. Number of hunks
    4. Average hunk size
    5. Number of lines changed (i.e. all lines with +/- indicators in the original
       diff generated from pre-fix and post-fix versions).
    6. Boolean tangled_hunks: True meaning the commit has at least one tangled hunk
    7. Boolean tangled_lines: True meaning the commit has at least one tangled line

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
from os import path
from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT

def count_hunks(patch):
    '''
    Return the numbe of hunks in the diff file.

    Args:
        patch <PatchSet Object>: filtered, contain no context lines, comments, or import statements. 
    Return:
        count <Integer>: The number of hunks reported in the diff
    '''
    count = 0                       
    if len(patch) > 0:              # Non-empty patch
        for file in patch:
            count += len(file)
    return count

def count_changed_lines(patch):
    '''
    Return the numbe of changed lines (+)/(-) in the diff file.
    A line is called "changed" if it is either removed from the source file or added to the target file
    Args:
        patch <PatchSet Object>: filtered, contain no context lines, comments, or import statements. 
    Return:
        count <Integer>: The number of hunks reported in the diff
    '''
    count = 0
    if len(patch) > 0:              # Non-empty patch
        for file in patch:
            for hunk in file:
                count += len(hunk)
    return count

def tangled_hunks(original_diff, bug_fix_diff, nonfix_diff):
    all_hunks_count = count_hunks(original_diff)
    fix_hunks_count = count_hunks(bug_fix_diff)
    nonfix_hunks_count = count_hunks(nonfix_diff)
    
    tangled_hunks_count = (fix_hunks_count + nonfix_hunks_count) - all_hunks_count
    
    if tangled_hunks_count > 0:
        return True
    elif tangled_hunks_count == 0:
        return False
    else:
        return "There is a bug."
    
def tangled_lines(original_diff, bug_fix_diff, nonfix_diff):                # TODO: Can further reduce duplicated code for is_tangled lines and hunks into one
    all_lines_count = count_changed_lines(original_diff)
    fix_lines_count = count_changed_lines(bug_fix_diff)
    nonfix_lines_count = count_changed_lines(nonfix_diff)
    
    tangled_lines_count = (fix_lines_count + nonfix_lines_count) - all_lines_count
    
    if tangled_lines_count > 0:
        return True
    elif tangled_lines_count == 0:
        return False
    else:
        return "There is a bug."

def main():
    """
    Implement the logic of the script. See the module docstring for more
    information.
    """
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: patch | python3 commit_metrics.py <project> <bug_id> <repo_root>")
        sys.exit(1)

    project = args[0]
    vid = args[1]
    repository = args[2]

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

    original_diff = PatchSet.from_filename(path.join(repository, "diff", "VC.diff"))
    bug_fix_diff = PatchSet.from_filename(path.join(repository, "diff", "bug_fix.diff"))
    nonfix_diff = PatchSet.from_filename(path.join(repository, "diff", "non_bug_fix.diff"))

    # TODO: With this implementation, we can return the number of tangled hunks and tangled lines.
    # The question is, is this way of detecting tangled hunks and lines naive, as it gives too much trust to Defects4J file? Defects4J can be buggy.
    # However, testing on sample reliable bug files show that this is for now correct.
    # Do we want the number of tangled hunks and lines instead?
    has_tangled_hunks = tangled_hunks(original_diff, bug_fix_diff, nonfix_diff)
    has_tangled_lines = tangled_lines(original_diff, bug_fix_diff, nonfix_diff)

    print(
        f"{project},{vid},{files_updated},{test_files_updated},"
        f"{hunks},{average_hunk_size},{lines_updated},"
        f"{has_tangled_hunks},{has_tangled_lines}"
    )

if __name__ == "__main__":
    main()
