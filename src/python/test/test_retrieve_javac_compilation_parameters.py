"""
Tests for the retrieve_javac_compilation_parameters module.
"""
import json

from src.python.main.retrieve_javac_compilation_parameters import (
    retrieve_compilation_parameter,
)


def test_sourcepath_across_javac_run():
    """
    Test that the sourcepath parameter is correctly retrieved across multiple javac runs.
    The multiple sourcepath should be appended together with ':' as the separator.
    """

    # Load the JSON file
    with open("src/python/test/javac.json") as f:
        scores = json.load(f)

    # Retrieve the parameter
    parameter_value = retrieve_compilation_parameter("sourcepath", scores)

    assert (
        parameter_value
        == "/absolute/path/to/moved/source/filesA:/absolute/path/to/moved/source/filesB"
    )


def test_classpath_across_javac_run():
    """
    Test that the classpath parameter is correctly retrieved across multiple javac runs.
    The multiple classpath should be appended together with ':' as the separator.
    """

    # Load the JSON file
    with open("src/python/test/javac.json") as f:
        scores = json.load(f)

    # Retrieve the parameter
    parameter_value = retrieve_compilation_parameter("classpath", scores)

    assert (
        parameter_value
        == "/absolute/path/to/compiled/classes:/absolute/path/to/maven/libA:/absolute/path/to/maven/libB:/absolute/path/to/compiled/classes:/absolute/path/to/maven/libC:/absolute/path/to/maven/libD"
    )
