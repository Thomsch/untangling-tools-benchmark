"""
Utilities to read data from the evaluation results.
"""

import os
import pandas as pd

GROUND_TRUTH_COLUMNS = ['file','source','target','group']

def read_ground_truth(ground_truth_file: str) -> pd.DataFrame:
    """
    Reads the ground truth from a CSV file.
    """
    if not os.path.exists(ground_truth_file):
        raise FileNotFoundError(f"File {ground_truth_file} does not exist.")

    return pd.read_csv(ground_truth_file, header=0)