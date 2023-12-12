"""
Tests for print_performance.py
"""
import pytest

import src.python.main.analysis.print_performance as print_performance


@pytest.fixture
def sample_d4j_scores(tmpdir):
    """
    Create a sample decompositions.csv file.
    """
    data = """P1,1,0.8,0.7,0.6
P1,2,0.9,0.8,0.7
P2,1,0.7,0.6,0.5
P3,5,0.6,0.5,0.4
"""
    file = tmpdir.join("decompositions-d4j.csv")
    file.write(data)
    return str(file)

@pytest.fixture
def sample_lltc4j_scores(tmpdir):
    """
    Create a sample decompositions.csv file.
    """
    data = """P1,dca322,0.2,0.6,0.6
P1,aef4d3,0.9,0.2,0.7
P1,dca322,0.7,0.3,0.1
P2,aef4d3,0.9,0.5,0.7
"""
    file = tmpdir.join("decompositions-lltc4j.csv")
    file.write(data)
    return str(file)


def test_calculate_performance(sample_d4j_scores, sample_lltc4j_scores, capfd):
    """
    Tests that the performance metrics are calculated correctly.
    """
    print_performance.main(sample_d4j_scores, sample_lltc4j_scores, "median", False)

    captured = capfd.readouterr()

    expected_standard_output = (
        "\\begin{tabular}{lrrr}\n"
        "\\toprule\n"
        " & Flexeme & SmartCommit & File-based \\\\\n"
            "Dataset &  &  &  \\\\\n"
            "\\midrule\n"
        "Defects4J & 0.65 & \\bfseries 0.75 & 0.55 \\\\\n"
            "LLTC4J & 0.40 & \\bfseries 0.80 & 0.65 \\\\\n"
            "\\bottomrule\n"
        "\\end{tabular}\n"
        "\n"
    )

    expected_error_output = (
        "\\newcommand\\defectsfjFlexemeMedian{0.65\\xspace}\n"
        "\\newcommand\\defectsfjSmartcommitMedian{0.75\\xspace}\n"
        "\\newcommand\\defectsfjFilebasedMedian{0.55\\xspace}\n"
        "\\newcommand\\lltcfjFlexemeMedian{0.4\\xspace}\n"
        "\\newcommand\\lltcfjSmartcommitMedian{0.8\\xspace}\n"
        "\\newcommand\\lltcfjFilebasedMedian{0.65\\xspace}\n"
    )

    assert captured.out == expected_standard_output
    assert captured.err == expected_error_output

def test_calculate_performance(sample_d4j_scores, sample_lltc4j_scores, capfd):
    """
    Tests that the performance metrics are calculated correctly.
    """
    print_performance.main(sample_d4j_scores, sample_lltc4j_scores, "mean", False)

    captured = capfd.readouterr()

    expected_standard_output = (
        "\\begin{tabular}{lrrr}\n"
        "\\toprule\n"
        " & Flexeme & SmartCommit & File-based \\\\\n"
            "Dataset &  &  &  \\\\\n"
            "\\midrule\n"
        "Defects4J & 0.65 & \\bfseries 0.75 & 0.55 \\\\\n"
            "LLTC4J & 0.40 & \\bfseries 0.68 & 0.52 \\\\\n"
            "\\bottomrule\n"
        "\\end{tabular}\n"
        "\n"
    )

    expected_error_output = (
        "\\newcommand\\defectsfjFlexemeMean{0.65\\xspace}\n"
        "\\newcommand\\defectsfjSmartcommitMean{0.75\\xspace}\n"
        "\\newcommand\\defectsfjFilebasedMean{0.55\\xspace}\n"
        "\\newcommand\\lltcfjFlexemeMean{0.4\\xspace}\n"
        "\\newcommand\\lltcfjSmartcommitMean{0.68\\xspace}\n"
        "\\newcommand\\lltcfjFilebasedMean{0.52\\xspace}\n"
    )

    assert captured.out == expected_standard_output
    assert captured.err == expected_error_output


def test_calculate_performance_overall(sample_d4j_scores, sample_lltc4j_scores, capfd):
    """
    Tests that the performance metrics are calculated correctly.
    """
    print_performance.main(sample_d4j_scores, sample_lltc4j_scores, "mean", True)

    captured = capfd.readouterr()

    expected_standard_output = (
        "\\newcommand\\overallSmartcommitMean{0.71\\xspace}\n"
        "\\newcommand\\overallFlexemeMean{0.52\\xspace}\n"
        "\\newcommand\\overallFilebasedMean{0.54\\xspace}\n"
    )

    assert captured.out == expected_standard_output
    assert captured.err is ''
