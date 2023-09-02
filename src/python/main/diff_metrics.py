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
from os import path
from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT


def get_lines_in_hunk(hunk):
    """
    Return an ordered list of all unidiff Lines objects in the given hunk.
    All unidiff Line objects must be non-empty and must be either an added (+) or removed (-) line.
    """
    changed_lines = []
    for line in hunk:
        if line.line_type != LINE_TYPE_CONTEXT and line.value.strip():
            changed_lines.append(line)
    return changed_lines


def get_hunks_in_patch(patch):
    """
    Return an ordered list of all hunks in the given file.
    A hunk is represented as a list of unidiff Line objects.
    All unidiff Line objects must not be blank and must be either an added (+) or removed (-) line.
    We ignore empty hunks.
    """
    hunks = []
    for file in patch:
        for hunk in file:
            lines_in_hunk = get_lines_in_hunk(hunk)
            if len(lines_in_hunk) > 0:
                hunks.append(lines_in_hunk)
    return hunks


def lines_in_patch(patch):
    """
    As a PatchSet object is nested with 3 layers, this function
    flattens it such that only line objects are stored sequentially.
    All unidiff Line Objects must be must not be blank and must be
    either an added (+) or removed (-) line.
    """
    result = []
    for file in patch:
        for hunk in file:
            lines_in_hunk = get_lines_in_hunk(hunk)
            for line in lines_in_hunk:
                result.append(line)
    return result


def count_tangled_hunks(original_diff: PatchSet, fix_diff: PatchSet):
    """
    Count the number of tangled hunks in a Version Control diff.
    Args:
        original_diff: the Version Control diff.
        fix_diff: the bug-fixing diff.
    Returns:
        the number of tangles hunks.
    """
    tangled_hunks_count = 0
    hunks_VC = get_hunks_in_patch(original_diff)  # List of hunks
    # Obtain string representations of all Line Objects
    fix_diff_lines_str = [str(line) for line in lines_in_patch(fix_diff)]
    if len(fix_diff_lines_str) > 0 or len(fix_diff_lines_str) != count_changed_lines(
        original_diff
    ):
        for hunk in hunks_VC:
<<<<<<< HEAD
            # Find all fix lines in the hunk by matching diff line strings
            # TODO: Ideal to use object identity here, but for now opt for identity
            # by string representation instead; possible for this to be error prone.
            fix_lines_VC = [line for line in hunk if str(line) in fix_diff_lines_str]
||||||| e6fd546
            fix_lines_VC = [
                line for line in hunk if str(line) in fix_lines_str
            ]  # Find all fix lines in the hunk by matching diff line strings
=======
            # TODO: Ideal to use object identity here, but now opt for identity
            # by string representation instead; possible for this to be error prone.
            fix_lines_VC = [
                line for line in hunk if str(line) in fix_lines_str
            ]  # Find all fix lines in the hunk by matching diff line strings
>>>>>>> a9860be9ec4bcff2e68608d4c7428e4c9863b86f
            if len(fix_lines_VC) == 0 or len(fix_lines_VC) == len(hunk):
                continue  # The hunk is purely bug-fixing or non bug-fixing
            tangled_hunks_count += 1
    return tangled_hunks_count


def count_changed_lines(patch):
    """
    Return the number of non-blank changed unidiff diff lines (+)/(-) in the
    diff file (i.e. we ignore both blank lines and context lines).  A unidiff
    diff line is called "changed" if it is either removed from the source file
    or added to the target file.

    Args:
        patch <PatchSet Object>: cleaned, contain no context lines, comments, or import statements.
    Return:
        count <Integer>: The number of changed diff lines in the diff file

    """
    flat_patch = lines_in_patch(patch)
    return len(flat_patch)


def count_tangled_lines(original_diff, bug_fix_diff, nonfix_diff):
    """
    Return the number of tangled unidiff lines found in original VC diff.

    As tangled lines are duplicated, we return the count divided by 2.
    """
    all_lines_count = count_changed_lines(original_diff)
    fix_lines_count = count_changed_lines(bug_fix_diff)
    nonfix_lines_count = count_changed_lines(nonfix_diff)

    tangled_lines_count = fix_lines_count + nonfix_lines_count - all_lines_count
    if tangled_lines_count % 2 != 0:
        print(
            f"The number of tangled diff lines is not even: {tangled_lines_count}.",
            file=sys.stderr,
        )
        sys.exit(1)
    # For unified original diff to have no tangled line, this must hold true:
    # changed_lines_count(VC) = changed_lines_count(BF) + changed_lines_count(BF)
    tangled_lines_count = tangled_lines_count / 2
    # Handle D4J bug: excessive unidiff Lines in original diff
    return max(tangled_lines_count, 0)


def tangle_counts(repository):
    """
    Returns "tangled_lines_count,tangled_hunks_count".
    """

    original_diff = PatchSet.from_filename(
        path.join(repository, "diff", "VC_clean.diff"),
        encoding="latin-1",  # latin-1 is the best choice for an ASCII-compatible encoding
    )
    fix_diff = PatchSet.from_filename(
        path.join(repository, "diff", "BF.diff"), encoding="latin-1"
    )
    nonfix_diff = PatchSet.from_filename(
        path.join(repository, "diff", "NBF.diff"), encoding="latin-1"
    )

    tangled_lines_count = count_tangled_lines(original_diff, fix_diff, nonfix_diff)
    tangled_hunks_count = count_tangled_hunks(original_diff, fix_diff)

    return f"{tangled_lines_count},{tangled_hunks_count}"


def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: patch | python3 diff_metrics.py <project> <bug_id> <repo_root>")
        sys.exit(1)

    project = args[0]
    vid = args[1]
    repository = args[2]

    unclean_original_diff = PatchSet.from_filename(
        filename=path.join(repository, "diff", "VC.diff"),
        encoding="latin-1",  # latin-1 is the best choice for an ASCII-compatible encoding
    )
    clean_original_diff = PatchSet.from_filename(
        path.join(repository, "diff", "VC_clean.diff"), encoding="latin-1"
    )

    # Generate diff metrics on clean VC diff

    # The number of files updated, not including tests.
    files_updated = len(clean_original_diff)

    # Count the number of changed lines in the unclean VC diff
    all_changed_lines = 0
    test_files_updated = 0
    for file in unclean_original_diff:
        if file.path.endswith("Test.java"):
            test_files_updated += 1
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

    # The number of files updated, not including tests.
    files_updated = len(clean_original_diff)
    hunks_count = len(get_hunks_in_patch(clean_original_diff))
    code_changed_lines = len(lines_in_patch(clean_original_diff))
    average_hunk_size = (code_changed_lines / hunks_count) if hunks_count != 0 else ""

    print(
        f"{project},{vid},{files_updated},{test_files_updated},"
        f"{hunks_count},{average_hunk_size},{code_changed_lines},{all_changed_lines - code_changed_lines},"
        f"{tangle_counts(repository)}"
    )


if __name__ == "__main__":
    main()
