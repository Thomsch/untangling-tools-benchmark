#!/usr/bin/env python3
import csv
import os
import sys


def main():
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: filename_untangling.py <evaluation_root>")
        exit(1)

    root_dir = args[0]

    # Iterate through subdirectories and read truth.csv files
    for subdir, dirs, files in os.walk(root_dir):
        for file in files:
            if file == 'truth.csv':
                file_path = os.path.join(subdir, file)

                # Get project name from file path
                project_name = os.path.basename(os.path.dirname(file_path))

                # Print project name
                with open(file_path, 'r') as csv_file:
                    csv_reader = csv.reader(csv_file)

                    # Skip header row
                    next(csv_reader)

                    paths = {}
                    group_counter = 0

                    new_file_path=os.path.join(subdir, 'file_untangling.csv')

                    with open(new_file_path, 'w', newline='') as new_csv_file:
                        csv_writer = csv.writer(new_csv_file)
                        csv_writer.writerow(['group', 'file', 'source', 'target'])

                        for row in csv_reader:
                            file, source, target, _ = row

                            if file not in paths:
                                paths[file] = group_counter
                                group_counter += 1

                            group = paths[file]

                            # Print row with group column
                            csv_writer.writerow([file, source, target, group])


if __name__ == "__main__":
    main()