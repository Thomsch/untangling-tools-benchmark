import pandas as pd
from analysis.median_performance import calculate_performance

import pytest

@pytest.fixture
def sample_decompositions_csv(tmpdir):
    data = """A,1,0.8,0.7,0.6
A,2,0.9,0.8,0.7
B,1,0.7,0.6,0.5
B,2,0.6,0.5,0.4
"""
    file = tmpdir.join("decompositions.csv")
    file.write(data)
    return str(file)


def test_calculate_performance(sample_decompositions_csv, capfd):
    calculate_performance(sample_decompositions_csv)
    captured = capfd.readouterr()
    expected_output = (
        "Number of D4J bugs: 4\n"
        "SmartCommit Median: 0.75\n"
        "Flexeme Median: 0.65\n"
        "File Rand Index Median: 0.55\n"
    )
    assert captured.out == expected_output