#!/usr/bin/env python3

# Counts the number of bug fixing lines and other lines from the ground truth.

import sys
import pandas as pd

def main():
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: count_lines.py <path/to/truth/file> <project> <bug_id>")
        exit(1)

    truth_file = args[0]
    project = args[1]
    vid = args[2]
    
    # "df" stands for "dataframe"
    truth_df = pd.read_csv(truth_file).convert_dtypes()

    fix_lines = truth_df['fix'].value_counts().get(True, default=0)
    other_lines = truth_df['fix'].value_counts().get(False, default=0)

    print(f'{project},{vid},{fix_lines},{other_lines}')

if __name__ == "__main__":
    main()

# LocalWords: dtypes
