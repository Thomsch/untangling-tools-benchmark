#!/usr/bin/env python3

"""
This script calculates the following 7 commit metrics for a provided D4J bug:
    1. Total number of files updated (i.e. both code and test files)
    2. Number of test files updated
    3. Number of hunks
    4. Average hunk size
    5. Number of lines changed (i.e. all lines with +/- indicators in the original
       diff generated from pre-fix and post-fix versions).
    6. A Boolean indicating if the commit has at least one tangled hunk
    7. A Boolean tangled_lines indicating if the commit has at least one tangled line

Command Line Args:
    project: D4J Project name
    vid: D4J Bug Id
    out_dir: Path where results are stored
    repo_root: Path where the repo is checked out
Returns:
    The results are stored in a {<project> <id>}.csv file (with 1 row) in <out_dir>/metrics folder.
    CSV header:
    {d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated, tangled_hunks, tangled_lines}
"""
import sys
from os import path
from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT
import clean_artifacts

def get_lines_in_hunk(hunk):
    '''
    Return an ordered List of all diff lines Objects in the given hunk.
    All lines must be non-empty and must be either an added (+) or removed (-) line.
    Args:
        hunk <Hunk Object>: filtered, contain no context lines, comments, or import statements. 
    Return:
        lines <List>: a set of unique diff line Objects.
    '''
    changed_lines = []
    for line in hunk:
        if line.line_type != LINE_TYPE_CONTEXT and line.value.strip():
            line.diff_line_no = None
            changed_lines.append(line)
    return changed_lines

def get_hunks_in_patch(patch):
    '''
    Return an ordered List of all hunks in the given file.
    A hunk is represented as a List of Line objects.
    All lines must be non-empty and must be either an added (+) or removed (-) line.
    We ignore empty hunks.
    Args:
        hunk <Hunk Object>: filtered, contain no context lines, comments, or import statements. 
    Return:
        lines <List>: a set of unique diff line Objects.
    '''
    hunked_lines = []
    for file in patch:
        for hunk in file:
            lines_in_hunk = get_lines_in_hunk(hunk)
            if len(lines_in_hunk) > 0:
                hunked_lines.append(lines_in_hunk)
    return hunked_lines

def flatten_patch_object(patch):
    '''
    As a PatchSet Object is nested with 3 layers, this function flattens it such that only line objects are stored at a hunk-level.
    Hunks from different files are sequentially stored as a List of diff Line objects.
    All lines must be non-empty and must be either an added (+) or removed (-) line.
    '''
    flat_patch = []
    for file in patch:
        for hunk in file:
            lines_in_hunk = get_lines_in_hunk(hunk)
            for line in lines_in_hunk:
                flat_patch.append(line)
    return flat_patch

def tangled_hunks(original_diff, fix_diff):
    '''
    Count the number of tangled hunks in a Version Control diff.

    Args:
        original_diff <PatchSet Object>: the Version Control diff.
        fix_diff <PatchSet Object>: the bug-fixing diff.
    Returns:
        Boolean: True if there is at least 1 tangled hunk. 
    '''
    tangled_hunks_count = 0
    hunks_VC = get_hunks_in_patch(original_diff)
    fix_lines = flatten_patch_object(fix_diff)
    if len(fix_lines) > 0 or len(fix_lines) != sum([len(hunk) for hunk in hunks_VC]):
        for hunk in hunks_VC:
            fix_lines_VC = [line for line in hunk if line in fix_lines]
            if len(fix_lines_VC) == 0 or len(fix_lines_VC) == len(hunk):
                continue
            tangled_hunks_count += 1
    print(f"Number of tangled hunks: {tangled_hunks_count}")
    return tangled_hunks_count > 0

            
def count_changed_lines(patch):
    '''
    Return the number of nonempty changed lines (+)/(-) in the diff file.
    A line is called "changed" if it is either removed from the source file or added to the target file
    Args:
        patch <PatchSet Object>: filtered, contain no context lines, comments, or import statements. 
    Return:
        count <Integer>: The number of hunks reported in the diff
    '''
    flat_patch = flatten_patch_object(patch)
    return len(flat_patch)

def tangled_lines(original_diff, bug_fix_diff, nonfix_diff):                # TODO: Can further reduce duplicated code for is_tangled lines and hunks into one
    all_lines_count = count_changed_lines(original_diff)
    fix_lines_count = count_changed_lines(bug_fix_diff)
    nonfix_lines_count = count_changed_lines(nonfix_diff)
    
    tangled_lines_count = (fix_lines_count + nonfix_lines_count - all_lines_count) // 2
    print(f"Number of tangled lines: {tangled_lines_count}")
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

    patch = PatchSet.from_filename(path.join(repository, "diff", "VC.diff"))

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

    clean_artifacts.clean_diff(path.join(repository, "diff", "VC.diff"))
    original_diff = PatchSet.from_filename(path.join(repository, "diff", "VC.diff"))
    fix_diff = PatchSet.from_filename(path.join(repository, "diff", "BF.diff"))
    nonfix_diff = PatchSet.from_filename(path.join(repository, "diff", "NBF.diff"))

    # Convert to dictionary representation

    # TODO: With this implementation, we can return the number of tangled hunks and tangled lines.
    # Do we want the number of tangled hunks and lines instead?
    has_tangled_lines = tangled_lines(original_diff, fix_diff, nonfix_diff)

    # if (has_tangled_lines):
    #     has_tangled_hunks = True
    # else:
    has_tangled_hunks = tangled_hunks(original_diff, fix_diff)
    
    print(
        f"{project},{vid},{files_updated},{test_files_updated},"
        f"{hunks},{average_hunk_size},{lines_updated},"
        f"{has_tangled_hunks},{has_tangled_lines}"
    )

if __name__ == "__main__":
    main()
#_lines(VC) = #_lines(BF) + #_lines(BF) 