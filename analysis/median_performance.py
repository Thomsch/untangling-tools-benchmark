#!/usr/bin/env python3

"""
Calculates the median performance for the untangling tools.
Input: `decompositions.csv` file produced by `evaluate.sh`
Output: Print the median performance for each untangling tool.
"""
import sys
import pandas as pd

def calculate_performance(decomposition_path):
    df_performance = pd.read_csv(decomposition_path, names=['project', 'bug_id', 'smartcommit_rand_index','flexeme_rand_index','file_rand_index.csv'])
    
    agg_results = df_performance.agg({'bug_id':'count', 'smartcommit_rand_index':'median',
                                      'flexeme_rand_index':'median', 'file_rand_index.csv':'median'})
    
    bug_count = int(agg_results['bug_id'])
    smartcommit_median = agg_results['smartcommit_rand_index']
    flexeme_median = agg_results['flexeme_rand_index']
    file_rand_index_median = agg_results['file_rand_index.csv']
    
    print(f"Number of D4J bugs: {bug_count}")
    print(f"SmartCommit Median: {smartcommit_median:.2f}")
    print(f"Flexeme Median: {flexeme_median:.2f}")
    print(f"File Rand Index Median: {file_rand_index_median:.2f}")
    

def main():
    args = sys.argv[1:]

    if len(args) != 1:
        print("Expected 1 argument: <decompositions.csv>")
        exit(-1)

    decomposition_path=args[0]
    calculate_performance(decomposition_path)

if __name__ == "__main__":
    main()
