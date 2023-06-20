# Retrieves the changed lines for a diff.
# The diff is passed to the script via stdin.
import os
import sys

from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT


def to_csv(patch: PatchSet):
    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                yield f"{file.path},{line.source_line_no},{line.target_line_no}"
                # ,\"{line.value.strip()}\"'


def from_file(filename):
    result = ""

    if os.path.exists(filename):
        patch = PatchSet.from_filename(filename)
        for line in to_csv(patch):
            result += line + "\n"

    return result


def main():
    patch = PatchSet.from_string(sys.stdin.read())

    for line in to_csv(patch):
        print(line)


if __name__ == "__main__":
    main()

# LocalWords: unidiff
