#!/usr/bin/env python3
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
