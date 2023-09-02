#!/usr/bin/env python3

"""
Translates SmartCommit grouping results (JSON files) in decomposition/smartcommit for each D4J bug
file to the line level. Each line is labelled with the group it belongs to and this is reported in
a readable CSV file.

Command Line Args:
    - result_dir: Path to JSON results in decomposition/smartcommit
    - output_path: Path to store returned CSV file in evaluation/smartcommit.csv
Returns:
    A smartcommit.csv file in the respective evaluation/<D4J bug> subfolder.
    CSV header: {file, source, target, group}
        - file: The relative file path from the project root for a change
        - source: The line number of the change if the change is a deletion
        - target: The line number of the change if the change is an addition
        - group: The group number of the change determined by SmartCommit (e.g, 'group0','group1')
"""

import glob
import json
import os
import sys
from io import StringIO

import pandas as pd
from unidiff import PatchSet

from parse_patch import to_csv
from parse_utils import export_tool_decomposition_as_csv


def list_json_files(dir):
    """
    Returns the JSON files contained in the specific directory.
    """
    return glob.glob(os.path.join(dir, "*.json"))


def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    args = sys.argv[1:]

    if len(args) != 2:
        print(
            "usage: parse_smartcommit_results.py <path/to/root/results> <path/to/out/file>"
        )
        sys.exit(1)

    result_dir = args[0]
    output_path = args[1]

    diff_dir = os.path.join(result_dir, "diffs")
    groups_dir = os.path.join(result_dir, "generated_groups")

    diff_data = read_results(diff_dir)
    result = generate_csv(diff_data, groups_dir)

    export_csv(output_path, result)


def read_results(diff_dir):
    """
    Read the decomposition results from disk. Each JSON file in the diff directory contains the
    diff data for a single file. We retrieve the hunk id, hunk header, raw diff, start line, and
    end line for each hunk in the file. The file is indexed by its file id defined in the JSON.

    Args:
        diff_dir: The path to the directory containing the JSON files with the diffs.

    Returns:
        A dictionary mapping file ids to dictionaries mapping hunk ids to tuples containing the
        hunk header, start line, end line, and raw diff.
    """
    diff_data = {}
    # Load diffs
    for diff_path in list_json_files(diff_dir):
        with open(diff_path, "r") as diff_file:
            data = json.load(diff_file)
            class_path = data["currentRelativePath"]
            file_id = data["fileID"]

            hunks = {}
            diff_data[file_id] = hunks

            hunks["rawHeaders"] = data["rawHeaders"]

            # Save data for each hunk
            for hunk_data in data["diffHunksMap"].values():
                hunk_id = hunk_data["diffHunkID"]
                start_line = hunk_data["currentHunk"]["startLine"]
                end_line = hunk_data["currentHunk"]["endLine"]

                hunks[hunk_id] = (
                    class_path,
                    start_line,
                    end_line,
                    hunk_data["rawDiffs"],
                )
    return diff_data


def generate_csv(diff_data, groups_dir):
    """
    Generate the CSV file from the diff data and the groups.

    Args:
        diff_data: The diff data loaded from the JSON files.
        groups_dir: The path to the directory containing the JSON files with the groups.

    Returns:
        A string containing the group data in CSV format.
    """
    result = ""

    # Print CSV for each group
    for group_path in list_json_files(groups_dir):
        with open(group_path, "r") as group_file:
            data = json.load(group_file)

            hunks = data["diffHunkIDs"]
            group_id = data["groupID"]

            for hunk in hunks:
                patch = make_patch(diff_data, hunk)

                # Break down the group for a hunk into its individual lines.
                for line in to_csv(patch):
                    result += f"{line},{group_id}\n"
    return result


def make_patch(diff_data, hunk) -> PatchSet:
    """
    Make a patch from the diff data and the hunk id.

    Args:
        diff_data: The diff data loaded from the JSON files.
        hunk: The hunk id of the hunk to make a patch from.

    Returns:
        A PatchSet object containing the patch for the hunk.
    """
    file_id, hunk_id = hunk.split(":")
    class_path, start_line, end_line, raw_diff = diff_data[file_id][hunk_id]
    header_str = "\n".join(diff_data[file_id]["rawHeaders"])
    diff_str = "\n".join(raw_diff)

    return PatchSet.from_string(header_str + "\n" + diff_str)


def export_csv(output_path, result):
    """
    Export the results to a CSV file.

    Args:
        output_path: The path to the CSV file to be created.
        result: The string containing the results to be written to the CSV file.
    """
    df = pd.read_csv(
        StringIO(result), names=["file", "source", "target", "group"], na_values="None"
    )
    df = df.convert_dtypes()  # Forces pandas to use ints in source and target columns.
    export_tool_decomposition_as_csv(df, output_path)


if __name__ == "__main__":
    main()
