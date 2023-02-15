# Calculates the Rand Index for the clusters per tool compared to ground truth.

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

def calculate_score_for_tool(truth_df, tool_df):
    df = pd.merge(truth_df, tool_df, on=['file', 'source', 'target'], how='left')
    df['group'] = df['group'].fillna('o') # Fill changed lines that are unclassified as other changes ('o').

    labels_pred = df['group']
    labels_true = df['fix']

    ## Adjust cluster to not penalize multiple groups containing exclusively
    ## non bug fixing changes.
    df_adjusted = adjust_groups(df)
    labels_pred = df_adjusted['group']
    labels_true = df_adjusted['fix']

    # The adjusted rand score (not the same as the adjusted clusters above!)
    # give a score of 0 when the fix is divided in multiple groups, which is unfair.
    # smartcommit_score = metrics.adjusted_rand_score(labels_true, labels_pred)
    return metrics.rand_score(labels_true, labels_pred)


def main():
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: untangling_score.py <evaluation/project/bug_id> <project> <bug_id>")
        exit(1)

    root = args[0]
    project = args[1]
    vid = args[2]
    
    truth_file = path.join(root,'truth.csv')
    smartcommit_file = path.join(root,'smartcommit.csv')
    flexeme_file = path.join(root,'flexeme.csv')

    truth_df = pd.read_csv(truth_file).convert_dtypes()
    smartcommit_df = pd.read_csv(smartcommit_file).convert_dtypes()
    flexeme_df = pd.read_csv(flexeme_file).convert_dtypes()
    flexeme_df['group'] = flexeme_df['group'].astype('string')

    smartcommit_score = calculate_score_for_tool(truth_df, smartcommit_df)
    flexeme_score = calculate_score_for_tool(truth_df, flexeme_df)

    print(f'{project},{vid},{smartcommit_score},{flexeme_score}')
if __name__ == "__main__":
    main()

# LocalWords: smartcommit dtypes isin sklearn flexeme astype