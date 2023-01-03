# Takes in the ground truth and the groups
# Outputs for each group:
# type, precision, recall,
# bug-fixing, x, x
# non bug-fixing, x, x
from os import path
import sys
import pandas as pd
import numpy as np

from sklearn.metrics import precision_score
from sklearn.metrics import recall_score

def main():
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: compute_metrics.py <evaluation/project/bug_id>")
        exit(1)

    root = args[0]
    truth_file = path.join(root,'truth.csv')
    groups_file = path.join(root,'groups.csv')
    truth_df = pd.read_csv(truth_file).convert_dtypes()
    groups_df = pd.read_csv(groups_file).convert_dtypes()
    
    # groups_df = groups_df[~groups_df['file'].str.endswith(('Test.java'))] # remove test files.

    # TODO Per group
    print('Bug fixing:')
    # print(groups_df)
    # print(truth_df)

    df = pd.merge(truth_df, groups_df, on=['file', 'source', 'target'], how='left')
    print(df)

    # Precision for bug-fixing lines
    # Precision for non bug-fixing lines

    # Group
    # 5 lines buggy
    # 40 lines non-buggy 

    # Truth
    # 20 lines buggy
    # 10 lines non-buggy


    # found = groups_df.line.isin(truth_df.line)

    # recall = found.sum() / len(truth_df)
    # print(f"Recall {recall}")

    # precision = found.sum() / len(groups_df)
    # print(f"Precision {precision}")

    # # TODO Non-bug-fixing commits
    # truth_nbf_lines = []
    # nbf_found = groups_df.line.isin(truth_nbf_lines)
    # nbf_recall = nbf_found.sum() / len(truth_nbf_lines)
    # nbf_precision = nbf_found.sum() / len(groups_df)

    pred = np.ones(len(groups_df), dtype=bool) # if using sklearn method.
if __name__ == "__main__":
    main()