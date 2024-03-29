#!/usr/bin/env python3

"""
Retrieves the changed lines for a diff that is passed to the script via stdin.
Output: Writes out added (+) or removed(-) diff lines in the CSV format:
  - file (string)
  - source (int)
  - target (int)
"""
import os
import sys

from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT


def to_csv(patch: PatchSet):
    """
    Takes in a PatchSet and prints out only added/removed lines (i.e. ignores all context lines).
    """
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                yield f"{file.path},{line.source_line_no},{line.target_line_no}"
                # ,\"{line.value.strip()}\"'


def from_file(diff_file):
    """
    Takes in a diff filename and returns a CSV string of added/removed lines.
    """
    result = ""

    if os.path.exists(diff_file):
        patch = PatchSet.from_filename(diff_file, encoding="latin-1")
        for line in to_csv(patch):
            result += line + "\n"

    return result


def main():
    """
    Implement the logic of the script. See the module docstring.
    """

    patch = PatchSet.from_string(sys.stdin.read())

    for line in to_csv(patch):
        print(line)


if __name__ == "__main__":
    main()
