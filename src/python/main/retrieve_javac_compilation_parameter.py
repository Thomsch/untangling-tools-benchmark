#!/usr/bin/env python3

"""
Retrieves a compilation parameter, such as the classpath or sourcepath used
by the Java compiler for a commit.
This script assumes that `try-compile.sh` has been run for the commit and that
the JSON file containing call results has been generated.

If the specified compilation parameter exists, the script will write it to stdout.
Otherwise, it will exit with a non-zero exit.

Command Line Args:
    - --parameter: Name of the parameter to retrieve. Either 'sourcepath' or 'classpath'.
    - --javac-file: Path to the JSON file containing the call results.

Only one parameter can be retrieved at a time. If both are specified, the script
will exit with a non-zero exit code.
"""

import argparse
import json
import sys


def retrieve_compilation_parameter(parameter: str, json_file: dict) -> str:
    """
    Retrieves the compilation parameter from the JSON file containing the compilation results.
    The JSON file has the following structure:
    [
        {
            "java_files": ['file1.java', 'file2.java'],
            "javac_switches": {
                "sourcepath": "dir1:dir2:dir3:",
                "classpath": "dir1:dir2:dir3:",
                ...
            }
        },
        ...
    ]

    Args:
        parameter: Name of the parameter to retrieve. Either 'sourcepath' or 'classpath'.
        json_file: JSON file containing the compilation results.
    """
    parameter_value = []

    for call in json_file:
        if parameter in call["javac_switches"]:
            parameter_value.append(call["javac_switches"][parameter])

    return "".join(parameter_value).rstrip(":")


def main():
    """
    Implement the logic of the script. See the module docstring.
    """
    main_parser = argparse.ArgumentParser(
        prog="retrieve_javac_compilation_parameter.py",
        description=f"{__doc__}",
    )

    main_parser.add_argument(
        "-p",
        "--parameter",
        choices=["sourcepath", "classpath"],
        help="Parameter to retrieve",
        required=True,
    )

    main_parser.add_argument(
        "-j",
        "--javac-file",
        help="JSON file containing the compilation calls results",
        metavar="PATH",
        required=True,
    )

    args = main_parser.parse_args()

    # Load the JSON file
    with open(args.javac_file) as f:
        javac_file = json.load(f)

    # Retrieve the parameter
    parameter_value = retrieve_compilation_parameter(args.parameter, javac_file)

    if parameter_value is None:
        sys.exit(1)
    else:
        print(parameter_value)


if __name__ == "__main__":
    main()
