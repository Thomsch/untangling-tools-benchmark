# Calculates the ground truth from changed lines and the Defect4J bug-inducing patches.
# Saves the results in a csv file given in parameter.
import sys
import os

import pandas as pd
import numpy as np
from io import StringIO
import parse_patch

COL_NAMES=['file', 'source', 'target']
COL_TYPES={'source': 'int', 'target': 'int'}

def from_stdin() -> pd.DataFrame:
    """
    Parses a diff from stdin into a DataFrame.
    """
    return csv_to_dataframe(StringIO(sys.stdin.read()))

def from_file(path) -> pd.DataFrame:
    """
    Parses a diff from a file into a DataFrame.
    """
    data = parse_patch.from_file(path)
    return csv_to_dataframe(StringIO(data))


def csv_to_dataframe(csv_data: StringIO) -> pd.DataFrame:
    """
    Convert a CSV string stream into a DataFrame.
    """
    df = pd.read_csv(csv_data, names=COL_NAMES, na_values='None')
    df = df.convert_dtypes() # Forces pandas to use ints in source and target columns.
    return df


def from_defect4j_patches(defect4j_home:str, project:str, vid:int)-> pd.DataFrame:
    """
    Extracts patch files from Defect4J for specified project and bug id, and converts them into
    one DataFrame.
    """
    source_path= os.path.join(defect4j_home, "framework/projects", project, "patches", f"{vid}.src.patch")
    test_path= os.path.join(defect4j_home, "framework/projects", project, "patches", f"{vid}.test.patch")

    source_df = from_file(source_path)
    test_df = from_file(test_path)

    # Merge source patch and test patch.
    df = pd.concat([source_df, test_df], axis=0, ignore_index=True)

    # Transform bug-inducing patch into bug-fixing patch by inverting added and deleted lines.
    col_list = list(df)
    col_list[1], col_list[2] = col_list[2], col_list[1] # swap source and target columns.
    df.columns = col_list
    df = df[COL_NAMES]
    return df


def main():
    # pd.options.display.max_colwidth = 100
    # changes = PatchSet.from_string()

    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: file.py <path/to/root/results>")
        exit(1)

    defect4j_home = "/Users/thomas/Workplace/defects4j"
    project="Lang"
    vid=1
    out_path = args[0]



    minimal_patch = from_defect4j_patches(defect4j_home, project, vid)
    changes = from_stdin()

    # Check which truth are in changes and tag them as True in a new column.
    ground_truth = pd.merge(changes, minimal_patch, on=COL_NAMES, how='left', indicator='fix')
    ground_truth['fix'] = np.where(ground_truth.fix == 'both', True, False)
    ground_truth.to_csv(out_path, index=False)

if __name__ == "__main__":
    main()

# LocalWords: dtypes, dataframe