import os
import sys
from collections import defaultdict
import pandas as pd


def main(evaluation_dir):
    """
    Implement the logic of the script. See the module docstring.
    """
    required_files = {
        "flexeme.csv",
        "smartcommit.csv",
        "scores.csv",
        "truth.csv",
        "file_untangling.csv"
    }
    bug_folder_counter = 0
    tangled_commit_counter = 0
    print("List of tangled commits: ")
    # Walk through the directory tree starting from 'evaluation'
    for root, dirs, files in os.walk(evaluation_dir):
        bug_name = os.path.basename(root)
        # Check if the current directory is a bug_name folder
        if root != "evaluation" and len(files) > 0:
            # Check if all the required CSV files are present in the bug_name folder
            if "truth.csv" in set(files):
                bug_folder_counter += 1
                truth_df = pd.read_csv(os.path.join(root,"truth.csv"))
                labels = set(truth_df['group'])
                if len(labels) > 1:
                    tangled_commit_counter += 1
                    print(bug_name)
    print(f"Total number of bug folder visited: {bug_folder_counter}")
    print(f"Total number of tangled commit: {tangled_commit_counter}")
    return tangled_commit_counter

if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: count_tangled_commit.py <path/to/evaluation/root>")
        sys.exit(1)

    evaluation_root = os.path.abspath(args[0])
    evaluation_dir = os.path.join(evaluation_root, "evaluation")
    main(evaluation_dir)
