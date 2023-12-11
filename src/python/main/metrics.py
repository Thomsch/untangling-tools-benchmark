"""
Metric utilities
"""
import pandas as pd

def calculate_ground_truth_size_per_commit(dataframe : pd.DataFrame) -> pd.DataFrame:
    return dataframe[['project', 'commit_id', 'file']].groupby(['project', 'commit_id']).count().reset_index().rename(columns= {'file':'count'})
