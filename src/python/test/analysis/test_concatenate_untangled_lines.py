import pandas as pd
import pytest

from src.python.main.analysis.concatenate_untangled_lines import normalize_untangled_lines


@pytest.fixture
def sample_data():
    # Define sample data for testing
    truth_data = {
        "file": ["file1", "file2", "file3"],
        "source": [1, "NA", 3],
        "target": ["NA", 5, "NA"],
        "group": ["fix", "fix", "other"],
    }

    tool_data = {
        "file": ["file1", "file2", "file4"],
        "source": [1, "NA", 6],
        "target": ["NA", 5, "NA"],
        "group": ["x", "y", "z"],
    }

    truth_df = pd.DataFrame(truth_data)
    tool_df = pd.DataFrame(tool_data)

    return truth_df, tool_df

def test_normalize_untangled_lines(sample_data):
    truth_df, tool_df = sample_data
    result_df = normalize_untangled_lines(truth_df, tool_df)

    # The normalization should remove the row for file4
    # because it is not in the ground truth and add the row for file3
    # because it is in the ground truth but not in the tool results.
    # file1 = x
    # file2 = y
    # file3 = o
    assert result_df.shape[0] == 3
    assert result_df["group"].tolist() == ["x", "y", "o"]
