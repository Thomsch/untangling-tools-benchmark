#!/usr/bin/env python3

import glob
import json
import os
import sys
from io import StringIO

import pandas as pd
from unidiff import PatchSet


# Retrieves changed lines for SmartCommit results.

def list_json_files(dir):
    """
    Returns the JSON files contained in the specific directory.
    """
    return glob.glob(os.path.join(dir, '*.json'))


def main():
    args = sys.argv[1:]

    if len(args) != 2:
        print("usage: parse_smartcommit_results.py <path/to/root/results> <path/to/out/file>")
        exit(1)

    result_dir = args[0]
    output_path = args[1]

    diff_dir = os.path.join(result_dir, 'diffs')
    groups_dir = os.path.join(result_dir, 'generated_groups')

    diff_data = {}

    # Load diffs
    for diff_path in list_json_files(diff_dir):
        with open(diff_path, 'r') as diff_file:
            data = json.load(diff_file)
            class_path = data['currentRelativePath']
            file_id = data['fileID']

            hunks = {}
            diff_data[file_id] = hunks

            hunks['rawHeaders'] = data['rawHeaders']

            # Save data for each hunk
            for hunk_data in data['diffHunksMap'].values():
                hunk_id = hunk_data['diffHunkID']
                startLine = hunk_data['currentHunk']['startLine']
                endLine = hunk_data['currentHunk']['endLine']

                hunks[hunk_id] = (class_path, startLine, endLine, hunk_data['rawDiffs'])

    result = ''

    # Print CSV for each group
    for group_path in list_json_files(groups_dir):
        with open(group_path, 'r') as group_file:
            data = json.load(group_file)

            hunks = data['diffHunkIDs']
            group_id = data['groupID']

            for hunk in hunks:
                file_id, hunk_id = hunk.split(':')
                class_path, start_line, end_line, rawDiff = diff_data[file_id][hunk_id]

                header_str = '\n'.join(diff_data[file_id]['rawHeaders'])
                diff_str = '\n'.join(rawDiff)

                import parse_patch
                patch = PatchSet.from_string(header_str + '\n' + diff_str)
                for line in parse_patch.to_csv(patch):
                    result += f'{line},{group_id}\n'

    # Export results
    df = pd.read_csv(StringIO(result), names=['file', 'source', 'target', 'group'], na_values='None')
    df = df.convert_dtypes()  # Forces pandas to use ints in source and target columns.

    if not len(df):
        print('No results generated. Verify decomposition results and paths.', file=sys.stderr)
        exit(1)

    df.to_csv(output_path, index=False)


if __name__ == "__main__":
    main()

# LocalWords: unidiff
