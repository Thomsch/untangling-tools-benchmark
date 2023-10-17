#!/usr/bin/env python3
import sys
from os import path
from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT
import diff_metrics


def count_all_changed_lines(patch):
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
            "usage: patch | python3 diff_metrics.py <project> <bug_id> <repo_root> <diff version>"
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
        sizes = [0] * len(diff_sets)
        for i in range(len(diff_sets)):
            diff_file = diff_sets[i]
            patch = PatchSet.from_filename(
                path.join(repository, "diff", diff_file), encoding="latin-1"
            )
            sizes[i] = count_all_changed_lines(patch)
        print(f"{project},{vid},{sizes[0]},{sizes[1]},{sizes[2]}")
    else:  # Clean version
        diff_sets = clean_diffs
        sizes = [0] * len(diff_sets)
        for i in range(len(diff_sets)):
            diff_file = diff_sets[i]
            patch = PatchSet.from_filename(
                path.join(repository, "diff", diff_file), encoding="latin-1"
            )
            sizes[i] = diff_metrics.count_changed_lines(patch)
        print(f"{project},{vid},{sizes[0]},{sizes[1]},{sizes[2]}")


if __name__ == "__main__":
    main()
