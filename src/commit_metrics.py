import sys

from unidiff import PatchSet
from unidiff.constants import LINE_TYPE_CONTEXT

'''
This script calculates the following 5 commit metrics for a provided D4J bug: 
    1. Total number of files updated (non-exclusive)
    2. Number of test files updated
    3. Number of hunks
    4. Average hunk size
    5. Number of lines updated.
The results are stored as a .csv file (with 1 row) in <out_dir>/metrics folder. 

Command Line Args:
    project: D4J Project name
    vid: D4J Bug Id
    out_dir: Path where results are stored
    repo_root: Path where the repo is checked out
Returns:
    The results are stored in a {<project> <id>}.csv file (with 1 row) in <out_dir>/metrics folder. 
    <project> <id>.csv headerline: {d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated}
'''
def main():
    args = sys.argv[1:]

    if len(args) != 2:
        print("usage: patch | python3 commit_metrics.py <project> <bug_id>")
        exit(1)

    project = args[0]
    vid = args[1]
    
    patch = PatchSet.from_string(sys.stdin.read())

    files_updated = len(patch) # The number of files updated
    test_files_updated = 0 # Number of test files updated
    hunks = 0 # Number of hunks
    hunk_sizes = [] # Average size of hunks
    lines_updated = 0 # The number of lines updated in the commit
    contains_refactoring = False       
    different_changes_same_line = None

    for file in patch:
        if file.path.endswith("Test.java"):
            test_files_updated += 1

        for hunk in file:
            hunks += 1
            hunk_sizes.append(len(hunk))
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                lines_updated += 1

    average_hunk_size = sum(hunk_sizes) / len(hunk_sizes)
    
    print(f"{project},{vid},{files_updated},{test_files_updated},{hunks},{average_hunk_size},{lines_updated}")

    
if __name__ == "__main__":
    main()
