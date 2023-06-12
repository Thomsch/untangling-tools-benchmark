#!/usr/bin/env python3

"""
This is the naive file-based untangling approach: commits to multiple files are considered tangled,
i.e. each file is considered a group. The results are stored in /evaluation folder.

Command Line Args:
    file_path: Path to ground truth file
    output_file: Path to output file
Returns:
    A <project-id>/file_untangling.csv file containing the file-based classification group in each D4J bug file subfolder.
    header line: {file, source, target, group}
        - file: The relative file path from the project root for a change
        - source: The line number of the change if the change is a deletion
        - target: The line number of the change if the change is an addition
        - group: The group number of the change. Each file is assigned a different group number.
"""

import csv
import os
import sys

def main(file_path, output_file):

    # GET directory path of file_path
    path = os.path.dirname(file_path)
    # Print project name
    with open(file_path, 'r') as csv_file:
        csv_reader = csv.reader(csv_file)

        # Skip header row
        next(csv_reader)

        paths = {}
        group_counter = 0

        with open(output_file, 'w', newline='') as new_csv_file:
            csv_writer = csv.writer(new_csv_file)
            csv_writer.writerow(['file', 'source', 'target', 'group'])

            for row in csv_reader:
                file, source, target, _ = row

                # Each changed file is assigned to a group based on its path.
                if file not in paths:
                    paths[file] = group_counter
                    group_counter += 1
                group = paths[file]

                # Print row with group column
                csv_writer.writerow([file, source, target, group])


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 2:
        print("usage: filename_untangling.py <path/to/ground-truth/file> <path/to/output/file>")
        exit(1)
    main(args[0], args[1])
