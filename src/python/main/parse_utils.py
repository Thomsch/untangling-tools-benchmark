"""
This module contains utility functions for parsing and exporting decomposition results.
"""

import sys


def export_tool_decomposition_as_csv(df, output_file):
    """
    Export the dataframe to a CSV file. Print an error message if the dataframe is empty.

    Args:
        df: The dataframe to be exported. The dataframe represents the decomposition results for a tool.
        output_file: The path to the CSV file to be created.
    """
    if len(df) == 0:
        print(
            "No results generated. Verify decomposition results and paths.",
            file=sys.stderr,
        )
        sys.exit(1)
    df.to_csv(output_file, index=False)
