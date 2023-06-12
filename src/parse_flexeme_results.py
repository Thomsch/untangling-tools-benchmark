#!/usr/bin/env python3

"""
Translates Flexeme grouping results ((dot files) in decomposition/flexeme for each D4J bug file
to the line level.

Each line is labelled by collecting all of its nodes' groups (it is possible for one line to have multiple groups).
# TODO: Explain how we come down to only 1 group.

Command Line Args:
    - result_dir: Path to flexeme.dot results in decomposition/flexeme
    - output_path: Path to store returned CSV file in evaluation/flexeme.csv
Returns:
    A flexeme.csv file in the respective /evaluation/<D4J bug> subfolder.
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


def main():
    args = sys.argv[1:]

    if len(args) != 2:
        print("usage: parse_flexeme_results.py <path/to/root/results> <path/to/out/file>")
        exit(1)
    
    result_file = args[0]
    output_path = args[1]

    try:
        graph = nx.nx_pydot.read_dot(result_file)
    except FileNotFoundError:
        # Flexeme doesn't generate a PDG if it doesn't detect multiple groups.
        # In this case, we do not create a CSV file. The untangling score will be
        # calculated as if Flexeme grouped all changes in one group in `untangling_score.py`.
        print('PDG not found, skipping creation of CSV file', file=sys.stderr)
        exit(0)

    UPDATE_ADD = 'add'
    UPDATE_REMOVE = 'remove'

    result = ''
    for node, data in graph.nodes(data=True):
        if 'color' in data.keys():
            if not 'label' in data.keys():
                logging.error(f"Attribute 'label' not found in node {node}")
                continue

            color_attribute = data['color']
            if color_attribute == 'green':
                update_type = UPDATE_ADD
            elif color_attribute == 'red':
                update_type = UPDATE_REMOVE
            else:
                logging.error(f"Color {color_attribute} not supported in node {node}")
                continue

            # Get the label for this node. Flexeme prepends "%d:" to the label of the node.
            label_attribute = data['label']
            group = label_attribute.split(':')[0].replace('"', '')

            # Retrieve line
            span_attribute = data['span'].replace('"', '').split('-')
            span_start = int(span_attribute[0])
            span_end = int(span_attribute[1])

            file = data['filepath'].replace('"', '') if 'filepath' in data.keys() else data['cluster'].replace('"', '')
            for line in range(span_start, span_end + 1):
                if update_type == UPDATE_REMOVE:
                    result += f"{file},{line},,{group}\n"
                elif update_type == UPDATE_ADD:
                    result += f"{file},,{line},{group}\n"
                else:
                    logging.error(f"Update {update_type} unsupported")
                    continue

            # Merge results per line
            # Might not need to merge results per line since the data is calculated using a left join on the truth.

            df = pd.read_csv(StringIO(result), names=['file', 'source', 'target', 'group'], na_values='None')
            df = df.convert_dtypes() # Forces pandas to use ints in source and target columns.
            df = df.drop_duplicates()

            if not len(df):
                print('No results generated. Verify decomposition results and paths.', file=sys.stderr)
                exit(1)

            df.to_csv(output_path, index=False)

if __name__ == "__main__":
    main()
