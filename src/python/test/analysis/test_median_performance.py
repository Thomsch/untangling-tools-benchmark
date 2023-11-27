"""
Tests for median_performance.py
"""
import pytest

from analysis.paper.median_performance import print_performance


@pytest.fixture
def sample_decompositions_csv(tmpdir):
    """
    Create a sample decompositions.csv file.
    """
    data = """A,1,0.8,0.7,0.6
A,2,0.9,0.8,0.7
B,1,0.7,0.6,0.5
B,2,0.6,0.5,0.4
"""
    file = tmpdir.join("decompositions.csv")
    file.write(data)
    return str(file)


def test_calculate_performance(sample_decompositions_csv, capfd):
    """
    Tests that the performance metrics are calculated correctly.
    """
    print_performance(sample_decompositions_csv)
    captured = capfd.readouterr()
    expected_output = (
        "% All the data used in the text is one file so that it can be easily updated.\n"
        "% Generated automatically by median_performance.py in https://github.com/Thomsch/untangling-tools-benchmark\n"
        "\\newcommand\\dfjCommitsCount{4\\xspace}\n"
        "\\newcommand\\lltcfjCommitsCount{TODO\\xspace} % Manually update this number if it has changed\n"
        "\\newcommand\\dfjCommitCountFlexemeError{TODO\\xspace} % Manually update this number if it has changed\n"
        "\\newcommand\\lltcfjCommitCountFlexemeError{TODO\\xspace} % Manually update this number if it has changed\n"
        "\\newcommand\\smartCommitMedian{0.75\\xspace}\n"
        "\\newcommand\\flexemeMedian{0.65\\xspace}\n"
        "\\newcommand\\fileUntanglingMedian{0.55\\xspace}\n"
    )
    assert captured.out == expected_output
