# Retrieves the changed lines for a diff.
# The diff is passed to the script via stdin.
import sys

from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT

def main():
    patch = PatchSet.from_string(sys.stdin.read())

    for file in patch:
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue;
                # print(line.target_line_no, file.path, line.value.strip())
                print(f'{file.path}, {line.source_line_no}, {line.target_line_no}, \"{line.value.strip()}\"')

if __name__ == "__main__":
    main()

# LocalWords: unidiff