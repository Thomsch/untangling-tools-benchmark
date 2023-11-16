#!/usr/bin/env python3

"""
This script calculates the size, measured by number of lines changed, of three artifacts stored
obtained from the Version Control of a Defects4J bug project.

Command Line Args:
    project: D4J Project name
    vid: D4J Bug Id
    repository: Directory where the repo is checked out
    version: The postfix of the diff file name, "clean" or "unclean"
Returns:
    The results are stored in a <project>_<id>_version.csv file (with 1 row) in <out_dir>/metrics folder.
    CSV header:
    {d4j_project,d4j_bug_id,original_patch_size, bug_fix_patch_size, non_bug_fixing_patch_size}
"""
import sys
from os import path

from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT

import diff_metrics


def count_lines_with_whitespace(patch):
    """
    Returns number of lines changed (added, removed from the original file) in the patch.
    Including empty lines.
    """
    all_changed_lines = 0
    for file in patch:
        # if file.path.endswith("Test.java"):
        #     test_files_updated += 1
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                all_changed_lines += 1
    return all_changed_lines


def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    args = sys.argv[1:]

    if len(args) != 4:
        print(
            "usage: patch | python3 summary_statistics.py <project> <bug_id> <repo_root> <diff version>"
        )
        sys.exit(1)

    project = args[0]
    vid = args[1]
    repository = args[2]
    version = args[3]

    whitespace_free_diffs = ["VC.diff", "BF.diff", "NBF.diff"]
    clean_diffs = ["VC_clean.diff", "BF_clean.diff", "NBF_clean.diff"]

    if version == "whitespace":
        diff_sets = whitespace_free_diffs
    else:  # Clean version
        diff_sets = clean_diffs
    sizes = [0] * len(diff_sets)
    for i, diff_file in enumerate(diff_sets):
        patch = PatchSet.from_filename(
            path.join(repository, "diff", diff_file), encoding="latin-1"
        )
        if version == "whitespace":
            sizes[i] = count_lines_with_whitespace(patch)
        else:
            sizes[i] = diff_metrics.count_changed_source_code_lines(patch)
    print(f"{project},{vid},{sizes[0]},{sizes[1]},{sizes[2]}")


if __name__ == "__main__":
    main()
