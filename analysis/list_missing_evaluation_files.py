#!/usr/bin/env python3
import os
import sys

#
# This script checks if all the required files are present in the benchmark
#
def main(path):
    required_files = ['flexeme.csv', 'smartcommit.csv', 'scores.csv', 'truth.csv']
    missing_files = []

    # Walk through the directory tree starting from 'evaluation'
    for root, dirs, files in os.walk(path):
        # Check if the current directory is a project folder
        if root != 'evaluation' and len(files) > 0:
            # Check if all the required CSV files are present in the project folder
            missing = set(required_files) - set(files)
            if missing:
                missing_files.append((os.path.basename(root), list(missing)))

    # Print the list of projects and missing files
    if missing_files:
        print('The following projects are missing the following files:')
        for project, missing in missing_files:
            print(f'{project}: {", ".join(missing)}')
    else:
        print('All projects have the required files.')

if __name__ == '__main__':
    args = sys.argv[1:]

    if len(args) != 1:
        print('usage: check_benchmark.py <path/to/benchmark/root>')
        exit(1)

    benchmark_root = os.path.abspath(args[0])
    path=os.path.join(benchmark_root, 'evaluation')
    main(path)