
import pandas as pd

from src.python.main.newmetrics import count_lines_in_tool_untangling


def test_empty_frame():
    """Test length of empty dataframe"""
    df = pd.DataFrame()
    assert len(df) == 0


def test_non_empty_frame():
    """Test length of non-empty dataframe"""
    data=[['p1', 'c1', '3', '4'], ['p1', 'c2', '0', '4']]
    df = pd.DataFrame(data, columns=count_lines_in_tool_untangling.COLUMNS)
    assert len(df) == 2