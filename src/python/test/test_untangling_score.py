"""
Tests for untangling_score.py
"""


import os
import sys
import tempfile

import pandas as pd

from src.python.main.untangling_score import main


def test_main():
    """
    End-to-end test for untangling_score.py.
    """
    # Create temporary directory and CSV files
    with tempfile.TemporaryDirectory() as tmpdir:
        create_temporary_results(tmpdir)

        # Run main function with sample command line arguments
        project = "test_project"
        vid = "test_vid"
        args = [tmpdir, project, vid]
        # Expected output based on sample dataframes
        expected_output = f"{project},{vid},1.0,1.0,1.0\n"
        with tempfile.TemporaryFile(mode="w+") as tmpfile:
            # Redirect stdout to temporary file
            old_stdout = sys.stdout
            sys.stdout = tmpfile
            main(args)
            sys.stdout.seek(0)
            output = tmpfile.read()
            sys.stdout = old_stdout

        # Check if output is as expected
        assert output == expected_output


def create_temporary_results(tmpdir):
    """
    Create temporary CSV files with sample dataframes.
    """
    truth_file = os.path.join(tmpdir, "truth.csv")
    smartcommit_file = os.path.join(tmpdir, "smartcommit.csv")
    flexeme_file = os.path.join(tmpdir, "flexeme.csv")
    file_untangling_file = os.path.join(tmpdir, "file_untangling.csv")
    # Create sample dataframes
    truth_df = pd.DataFrame(
        {
            "file": ["file1", "file2", "file3"],
            "source": [1, None, 3],
            "target": [None, 2, None],
            "group": ["fix", "other", "fix"],
        }
    )
    smartcommit_df = pd.DataFrame(
        {
            "file": ["file1", "file2", "file3"],
            "source": [1, None, 3],
            "target": [None, 2, None],
            "group": ["group0", "group1", "group0"],
        }
    )
    flexeme_df = pd.DataFrame(
        {
            "file": ["file1", "file2", "file3"],
            "source": [1, None, 3],
            "target": [None, 2, None],
            "group": ["0", "1", "0"],
        }
    )
    file_untangling_df = pd.DataFrame(
        {
            "file": ["file1", "file2", "file3"],
            "source": [1, None, 3],
            "target": [None, 2, None],
            "group": ["group0", "group1", "group0"],
        }
    )
    # Write dataframes to CSV files
    truth_df.to_csv(truth_file, index=False)
    smartcommit_df.to_csv(smartcommit_file, index=False)
    flexeme_df.to_csv(flexeme_file, index=False)
    file_untangling_df.to_csv(file_untangling_file, index=False)
