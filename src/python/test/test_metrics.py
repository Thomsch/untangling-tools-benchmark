"""
Tests for calculating metrics
"""

import pytest
import pandas as pd

from src.python.main.metrics import is_tangled_patch, count_tangled_file


def convert_ground_truth_to_legacy(df: pd.DataFrame) -> pd.DataFrame:
    """
    Converts the ground truth to the legacy format.
    """
    result = df.copy()

    # Add legacy source and target columns
    # Put the line number in source if the change type is '-' (removed), otherwise put a missing value
    result["source"] = result["line"].where(result["change_type"] == "-", None)
    result["target"] = result["line"].where(result["change_type"] == "+", None)

    # drop the change_type and line column
    result = result.drop(columns=["change_type", "line"])
    return result


@pytest.fixture
def tangled_patch() -> pd.DataFrame:
    """
    Ground truth dataframe with tangled changes at the patch level.
    """
    return convert_ground_truth_to_legacy(
        pd.DataFrame(
            {
                "file": ["a.java", "a.java", "b.java", "b.java"],
                "change_type": ["+", "+", "+", "+"],
                "line": [1, 2, 3, 4],
                "group": ["1", "1", "2", "2"],
            }
        )
    )


@pytest.fixture
def single_concern_patch() -> pd.DataFrame:
    """
    Ground truth dataframe with no tangled changes.
    """
    return convert_ground_truth_to_legacy(
        pd.DataFrame(
            {
                "file": ["a.java", "a.java", "b.java", "b.java"],
                "change_type": ["+", "+", "+", "+"],
                "line": [1, 2, 3, 4],
                "group": ["1", "1", "1", "1"],
            }
        )
    )


@pytest.fixture
def one_tangled_file() -> pd.DataFrame:
    """
    Ground truth dataframe with one tangled change at the file level.
    """
    return convert_ground_truth_to_legacy(
        pd.DataFrame(
            {
                "file": ["a.java", "a.java"],
                "change_type": ["+", "+"],
                "line": [1, 2],
                "group": ["1", "2"],
            }
        )
    )


@pytest.fixture
def multiple_tangled_files() -> pd.DataFrame:
    """
    Ground truth dataframe with multiple tangled changes at the file level.
    """
    return convert_ground_truth_to_legacy(
        pd.DataFrame(
            {
                "file": ["a.java", "a.java", "a.java", "b.java", "b.java"],
                "change_type": ["+", "+", "+", "+", "+"],
                "line": [1, 2, 3, 4, 5],
                "group": ["1", "2", "2", "1", "2"],
            }
        )
    )


@pytest.fixture
def one_tangled_file_and_one_not_tangled_file() -> pd.DataFrame:
    """
    Ground truth dataframe with multiple tangled changes at different levels.
    """
    return convert_ground_truth_to_legacy(
        pd.DataFrame(
            {
                "file": ["a.java", "a.java", "c.java", "c.java"],
                "change_type": ["+", "+", "+", "+"],
                "line": [1, 2, 3, 4],
                "group": ["1", "2", "1", "1"],
            }
        )
    )


# TODO: Tangled patch only if no tangled files. One level cannot be tangled if the previous level is not tangled.


def test_is_tangled_patch(tangled_patch, single_concern_patch):
    """
    Test the compute_tangled_patch function.
    """
    assert is_tangled_patch(tangled_patch)
    assert not is_tangled_patch(single_concern_patch)


def test_count_tangled_file(
    tangled_patch,
    single_concern_patch,
    one_tangled_file,
    multiple_tangled_files,
    one_tangled_file_and_one_not_tangled_file,
):
    """
    Test the count_tangled_file function.
    """
    assert count_tangled_file(tangled_patch) == 0
    assert count_tangled_file(single_concern_patch) == 0
    assert count_tangled_file(one_tangled_file) == 1
    assert count_tangled_file(multiple_tangled_files) == 2
    assert count_tangled_file(one_tangled_file_and_one_not_tangled_file) == 1
