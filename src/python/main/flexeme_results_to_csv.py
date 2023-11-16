#!/usr/bin/env python3

"""
Translates Flexeme grouping results (dot files) to the line level.

Each line is labelled by collecting all of its nodes' groups (it is possible for one line
to have multiple groups).
# TODO: Explain how we come down to only 1 group.

Command Line Args:
    - result_dir: Directory to flexeme.dot results in decomposition/flexeme
    - output_file: Directory to store returned CSV file in evaluation/flexeme.csv
Writes:
    A flexeme.csv file in the evaluation/<D4J bug> subfolder.
    CSV header: {file, source, target, group=0,1,2,etc.}
        - file: The relative file path from the project root for a change
        - source: The line number of the change if the change is a deletion
        - target: The line number of the change if the change is an addition
        - group: The group number of the change determined by Flexeme.
"""

import logging
import sys
from io import StringIO

import networkx as nx
import pandas as pd

from parse_utils import export_tool_decomposition_as_csv

UPDATE_ADD = "add"
UPDATE_REMOVE = "remove"


def main():
    """
    Implement the logic of the script. See the module docstring.
    """

    args = sys.argv[1:]

    if len(args) != 2:
        print(
            "usage: flexeme_results_to_csv.py <path/to/flexeme/graph/file> <path/to/csv/file>"
        )
        sys.exit(1)

    result_file = args[0]
    output_file = args[1]

    try:
        graph = nx.nx_pydot.read_dot(result_file)
    except FileNotFoundError:
        # Flexeme doesn't generate a PDG if it doesn't detect multiple groups.
        # In this case, we do not create a CSV file. The untangling score will be
        # calculated as if Flexeme grouped all changes in one group in `untangling_score.py`.
        print(
            "PDG file " + result_file + "not found, skipping creation of CSV file",
            file=sys.stderr,
        )
        sys.exit(1)

    result = ""
    for node, data in graph.nodes(data=True):
        # Changed nodes are the only nodes with a color attribute.
        if "color" not in data.keys():
            continue

        if data["color"] not in ["green", "red"]:
            logging.error(f"Color {data['color']} not supported")
            continue

        if "label" not in data.keys():
            logging.error(f"Attribute 'label' not found in node {node}")
            continue

        group = get_node_label(data)
        span_start, span_end = get_span(data)
        update_type = get_update_type(data)

        file = (
            data["filepath"].replace('"', "")
            if "filepath" in data.keys()
            # then do nothing
            else data["cluster"].replace('"', "")
        )
        for line in range(span_start, span_end + 1):
            if update_type == UPDATE_REMOVE:
                result += f"{file},{line},,{group}\n"
            elif update_type == UPDATE_ADD:
                result += f"{file},,{line},{group}\n"
            else:
                logging.error(f"Update {update_type} unsupported")
                continue

        # Merge results per line. Might not need to merge results per line
        #  since the data is calculated using a left join on the truth.
        export_csv(output_file, result)


def export_csv(output_file, result):
    """
    Export the results to a CSV file.

    Args:
        output_file: The path to the CSV file to be created.
        result: The string containing the results to be written to the CSV file.
    """
    df = pd.read_csv(
        StringIO(result),
        names=["file", "source", "target", "group"],
        na_values="None",
    )
    df = df.convert_dtypes()  # Forces pandas to use ints in source and target columns.
    df = df.drop_duplicates()
    export_tool_decomposition_as_csv(df, output_file)


def get_update_type(data):
    """
    Get the update type for a graph node.

    Args:
        data: The data attribute of the graph node.

    Returns:
        The update type of the graph node as a string. Can be either UPDATE_ADD or UPDATE_REMOVE.
    """
    color_attribute = data["color"]
    if color_attribute == "green":
        return UPDATE_ADD
    if color_attribute == "red":
        return UPDATE_REMOVE
    raise ValueError(f"Color {color_attribute} not supported")


def get_span(data):
    """
    Get the line span for this node.

    Args:
        data: The data attribute of the node.

    Returns:
        The line span of the node as a tuple (span_end, span_start).
    """
    span_attribute = data["span"].replace('"', "").split("-")
    span_start = int(span_attribute[0])
    span_end = int(span_attribute[1])
    return span_start, span_end


def get_node_label(data):
    """
    Get the label for this node. Flexeme prepends "%d:" to the label of the node.

    Args:
        data: The data attribute of the node.

    Returns:
        The group label of the node.
    """
    label_attribute = data["label"]
    group = label_attribute.split(":")[0].replace('"', "")
    return group


if __name__ == "__main__":
    main()
