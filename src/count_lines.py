import sys
import pandas as pd

def main():
    '''
    Counts the number of bug-fixing lines and non-bug-fixing lines from the ground truth.
    The current implementation does not account for tangled lines.

    Command Line Args:
        - path/to/truth/file: 
        - project: D4J Project name
        - bug_id:  D4J Bug id
    Returns:
        A lines.csv file corresponding to the input truth.csv file for each D4J bug file.
        headerline: project,bug_id,fix_lines=bug-fixing lines,nonfix_line=non bug-fixing lines
    ''' 
    args = sys.argv[1:]

    if len(args) != 3:
        print("usage: count_lines.py <path/to/truth/file> <project> <bug_id>")
        exit(1)

    truth_file = args[0]    # Path to the generated ground truth: <prohect-id>/truth.csv file
    project = args[1]       # Name of Defects4J project
    vid = args[2]           # Id of bug in Defects4J project
    
    # "df" stands for "dataframe"
    truth_df = pd.read_csv(truth_file).convert_dtypes()

    fix_lines = truth_df['fix'].value_counts().get(True, default=0)
    other_lines = truth_df['fix'].value_counts().get(False, default=0)

    print(f'{project},{vid},{fix_lines},{other_lines}')

if __name__ == "__main__":
    main()

# LocalWords: dtypes
