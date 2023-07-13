#!/usr/bin/env python3

"""
Generates the line-wise ground truth using the original changes and the minimized version
of the D4J bug.
Each diff line is classified into either a non-bug-fixing or bug-fixing change.

The tests, comments, and imports are ignored from the original changes.
The current implementation cannot identify tangled lines (i.e. a line that belongs to both groups).

Command Line Args:
    project: D4J Project name
    vid: D4J Bug id
    path/to/root/results: Specified path to store CSV file returned

Returns:
    The ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
    CSV header: {file, source, target, group='fix','other'}
        - file = each Diff Line Object from the original dif generated
        - source = the line removed (-) from buggy version
        - target = the line added (+) to fixed version
"""

import os
import sys
from collections import defaultdict
from io import StringIO

import numpy as np
import pandas as pd
from unidiff import PatchSet, LINE_TYPE_CONTEXT, LINE_TYPE_REMOVED, LINE_TYPE_ADDED

COL_NAMES = ["file", "source", "target"]


def from_stdin() -> pd.DataFrame:
    """
    Parses a diff from stdin into a DataFrame.
    """
    return csv_to_dataframe(StringIO(sys.stdin.read()))


def csv_to_dataframe(csv_data: StringIO) -> pd.DataFrame:
    """
    Convert a CSV string stream into a DataFrame.
    """
    df = pd.read_csv(csv_data, names=COL_NAMES, na_values="None")
    df = df.convert_dtypes()  # Forces pandas to use ints in source and target columns.
    return df


def get_d4j_src_path(defects4j_home, project, vid):
    """
    Returns the path to the minimal bug-inducing source patch for a D4J bug.

    Args:
        defects4j_home: Path to the local Defects4J installation
        project: D4J project name
        vid: D4J bug id
    """
    return os.path.join(
        defects4j_home, "framework/projects", project, "patches", f"{vid}.src.patch"
    )


def get_d4j_test_path(defects4j_home, project, vid):
    """
    Returns the path to the minimal bug-inducing test patch for a D4J bug.

    Args:
        defects4j_home: Path to the local Defects4J installation
        project: D4J project name
        vid: D4J bug id
    """
    return os.path.join(
        defects4j_home, "framework/projects", project, "patches", f"{vid}.test.patch"
    )


def convert_to_dataframe(patch: PatchSet) -> pd.DataFrame:
    """
    Converts a PatchSet into a DataFrame and filters out tests, comments, imports, non-Java files.
    The filtering is done during the conversion to avoid iterating over the patch twice.

    The dataframe has the following columns:
        - file (str): Path of the file
        - source (int): Line number when the line is removed or changed
        - target (int): Line number when the line is added or changed
    """
    ignore_comments = True
    ignore_imports = True
    df = pd.DataFrame(columns=COL_NAMES)
    for file in patch:
        # Skip non-Java files.
        # lower() is used to catch cases where the extension is in upper case.
        # We need at least one file with the Java extension because a diff can have
        # the following cases:
        #   1. source_file is 'dev/null' and the target_file is
        #      'foo.java' (i.e. 'foo.java' was added)
        # 2. source_file is 'foo.java' and the target_file is
        #      'dev/null' (i.e. 'foo.java' was deleted)
        # 3. source_file is 'foo.java' and the target_file is
        #      'foo.java' (i.e. 'foo.java' was modified)
        if not (
            file.source_file.lower().endswith(".java")
            or file.target_file.lower().endswith(".java")
        ):
            continue

        # Skip test files. We need at least one version of the file to be a test file to cover addition, deletion,
        # and modification cases.
        if is_test_file(file.source_file) or is_test_file(file.target_file):
            continue

        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue

                # TODO: Lines starting with "*" are not always comments.
                if ignore_comments and (
                    line.value.strip().startswith("/*")
                    or line.value.strip().startswith("*/")
                    or line.value.strip().startswith("//")
                    or line.value.strip().startswith("*")
                ):
                    continue
                if ignore_imports and line.value.strip().startswith("import"):
                    continue

                # Ignore whitespace only lines.
                if not line.value.strip():
                    continue

                entry = pd.DataFrame.from_dict(
                    {
                        "file": [file.path],
                        "source": [line.source_line_no],
                        "target": [line.target_line_no],
                    }
                )
                df = pd.concat([df, entry], ignore_index=True)
    return df


def is_test_file(filename):
    """
    Returns True if the filename is a filename for tests.

    This implementation currently works for all Defects4J 2.0.0 projects.
    """
    return (
        "/test/" in filename
        or "/tests/" in filename
        or filename.startswith("test/")
        or filename.startswith("tests/")
        or filename.endswith("Test.java")
    )


def get_line_map(diff) -> dict:
    """
    In a diff, we define a changed line as either a line removed from the original (pre-fix) file,
    indicated with (-), or a line added to the modified (post-fix) file, indicated with (+).
    An unchanged line is a context line, indicated with (' ').

    The function generates a map from line contents (i.e. either added/removed contents) to
    their line numbers in the diff provided.

    The mapping is one-to-many as identical lines of bug-fixing code can occur multiple times in
    the original diff.

    Args:
        diff: a PatchSet object (i.e. list of PatchFiles)
    Returns:
        line_map: a dictionary
            {key = line content, a String representation of line_type and line_value,
             value = a list of tuples (line, source_line_no, target_line_no)}
    """
    line_map = defaultdict(list)

    for file in diff:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:  # Ignore context lines.
                    continue
                line_map[str(line)].append(
                    (line, line.source_line_no, line.target_line_no)
                )

    return line_map


def invert_patch(patch):
    """
    Inverts the minimized bug-inducing patch of D4J bug fix dataset to a minimal bug-fix patch that
    can be applied to the buggy program by flipping the line type of change (addition/deletion) and
    updating the line numbers.

    Args:
        patch: a PatchSet object (i.e. list of PatchFiles)
    Returns:
        The same patch with diff Line objects inverted, modified in-place.
    """
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue

                if line.line_type in (LINE_TYPE_ADDED, LINE_TYPE_REMOVED):
                    tmp = line.source_line_no
                    line.source_line_no = line.target_line_no
                    line.target_line_no = tmp

                if line.line_type == LINE_TYPE_ADDED:
                    line.line_type = LINE_TYPE_REMOVED
                elif line.line_type == LINE_TYPE_REMOVED:
                    line.line_type = LINE_TYPE_ADDED

    return patch


def repair_line_numbers(patch_diff, original_diff):
    """
    Replaces the line numbers for bug-fixing lines with the line numbers from the original diff.
    If the same bug-fix (i.e. Line Object-wise) re duplicated, we will select its first occurrence
    in original diff as the original line.
    We ignore Line Objects that are not whole (i.e. DNE in original_diff)

    Args:
        patch_diff: the minimized D4J bug-fixing diff
    Returns:
        The updated patch (in which each bug-fixing Line Object is modified in place).
    """
    # Get the reference line number for the content of each changed line.
    line_map = get_line_map(original_diff)

    # Update the patch with the correct line numbers
    for file in patch_diff:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue

                if str(line) in line_map:
                    line_records = line_map[str(line)]
                    if len(line_records) == 0:
                        print(
                            f"Minimized line"
                            f" '{line.value.rstrip()}' {line.target_line_no, line.source_line_no}"
                            f" is not in the original diff."
                            f" The minimized line may contain partial changes,"
                            f" new changes, or be incorrectly minimized.",
                            file=sys.stderr,
                        )
                        continue

                    original_line = line_records.pop(0)[0]
                    line.source_line_no = original_line.source_line_no
                    line.target_line_no = original_line.target_line_no
                    line.line_type = original_line.line_type
                else:  # Bug-fixing portion of a tangled line.
                    # TODO: This should be classified as tangled rather than
                    # non-bug-fixing ("both", not "other")
                    print(
                        f"Line not found ({line.source_line_no}, {line.target_line_no}): '{line}'",
                        file=sys.stderr,
                    )
    return patch_diff


def main():
    """
    Implement the logic of the script. See the module docstring.
    """

    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: ground_truth.py <project> <vid> <path/to/root/results>")
        sys.exit(1)

    project = args[0]
    vid = args[1]
    out_path = args[2]

    defects4j_home = os.getenv("DEFECTS4J_HOME")
    if not defects4j_home:
        print("DEFECTS4J_HOME environment variable not set. Exiting.")
        sys.exit(1)

    changes_diff = PatchSet.from_string(sys.stdin.read())  # original programmer diff

    # Convert the diff to a dataframe for easier manipulation.
    # The PatchSet is not easy or efficient to work with because
    # it uses nested iterable objects.
    changes_df = convert_to_dataframe(changes_diff)

    # A diff Line object has (1) a Line Type Indicator (+/-/' ') (self.line_type), (2) Line Number
    # (self.source_line_no,self.target_line_no), and (3) Line Content (self.value).  A purely
    # bug-fix Line Object will be in the minimized bug-fix patch, this Line Object is identical to
    # the one in original_diff PatchSet.  A tangled line will only have a bug-fix portion (i.e. a
    # Line Object with different instance variables) in the minimized patch, thus DNE in
    # original_diff.  These tangled lines will not be counted as part of the minimal_bug_fixing
    # Patch.
    try:
        src_patch = PatchSet.from_filename(
            get_d4j_src_path(defects4j_home, project, vid)
        )
        src_patch = invert_patch(src_patch)
        src_patch = repair_line_numbers(src_patch, changes_diff)
        src_patch_df = convert_to_dataframe(src_patch)
    except FileNotFoundError:
        src_patch_df = pd.DataFrame(columns=COL_NAMES)

    # The minimal bug-fixing patch contains only the bug-fixing lines on the source code. The changed lines in the
    # test files are excluded.
    minimal_bugfix_patch = src_patch_df

    # Check which truth are in changes and tag them as True in a new column.
    ground_truth = pd.merge(
        changes_df, minimal_bugfix_patch, on=COL_NAMES, how="left", indicator="group"
    )
    ground_truth["group"] = np.where(ground_truth.group == "both", "fix", "other")
    ground_truth.to_csv(out_path, index=False)


if __name__ == "__main__":
    main()
