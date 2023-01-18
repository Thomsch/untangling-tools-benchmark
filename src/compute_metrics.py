# Takes in the ground truth and the groups
# Outputs for each group:
# type, precision, recall,
# bug-fixing, x, x
# non bug-fixing, x, x
from os import path
import sys
import pandas as pd
from sklearn import metrics

def adjust_groups(df: pd.DataFrame) -> pd.DataFrame:
    """
    Merge clusters without any bug fixing changes into one group named 'o'.
    'o' stands for Other changes.
    """
    groups = is_other_change(df)
    df['adjusted_group'] = df['group'].isin(groups[groups].index)

    df.loc[df['adjusted_group'], 'group'] = 'o'

    return df.drop(['other_change', 'adjusted_group'], axis=1)

def is_other_change(df: pd.DataFrame):
    """
    For each group, return whether the group contains only non bug-fixing changes or not.
    If a group only has bug fixing changes, return True.
    """
    df['other_change'] = ~df['fix'] # New column to keep track of non bug-fixing changes.
    return df.groupby('group')['other_change'].all() # Which groups only have non-bug-fixing changes.


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


    df = pd.merge(truth_df, groups_df, on=['file', 'source', 'target'], how='left')
    print(df)
    labels_pred = df['group']
    labels_true = df['fix']
    print(metrics.rand_score(labels_true, labels_pred))
    print(metrics.adjusted_rand_score(labels_true, labels_pred))

    df_adjusted = adjust_groups(df)
    print(df_adjusted)

    labels_pred = df_adjusted['group']
    labels_true = df_adjusted['fix']
    print(metrics.rand_score(labels_true, labels_pred))
    print(metrics.adjusted_rand_score(labels_true, labels_pred))
if __name__ == "__main__":
    main()