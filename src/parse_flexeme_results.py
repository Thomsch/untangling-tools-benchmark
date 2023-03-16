import logging
import sys
from io import StringIO

import networkx as nx
import pandas as pd


# Retrieves changed lines for Flexeme results.

def main():
    args = sys.argv[1:]

    if len(args) != 2:
        print("usage: this_script.py <path/to/root/results> <path/to/out/file>")
        exit(1)
    
    result_file = args[0]
    output_path = args[1]

    graph = nx.nx_pydot.read_dot(result_file)

    result = ''
    for node, data in graph.nodes(data=True):
        if 'color' in data.keys():
            if not 'label' in data.keys():
                logging.error(f"Attribute 'label' not found in node {node}")
                continue

            UPDATE_ADD = 'add'
            UPDATE_REMOVE = 'remove'

            color_attribute = data['color']
            if color_attribute == 'green':
                update_type = UPDATE_ADD
            elif color_attribute == 'red':
                update_type = UPDATE_REMOVE
            else:
                logging.error(f"Color {color_attribute} not supported in node {node}")
                continue

            label_attribute = data['label']

            # Get the label for this node. Flexeme prepend %d: to the label of the node.
            group = label_attribute.split(':')[0].replace('"', '')

            # Retrieve line
            span_attribute = data['span'].replace('"', '').split('-')
            span_start = int(span_attribute[0])
            span_end = int(span_attribute[1])

            file = data['filepath'].replace('"', '') if 'filepath' in data.keys() else data['cluster'].replace('"', '')
            for line in range(span_start, span_end + 1):
                if update_type == UPDATE_REMOVE:
                    result += f"{group},{file},{line},\n"
                elif update_type == UPDATE_ADD:
                    result += f"{group},{file},,{line}\n"
                else:
                    logging.error(f"Update {update_type} unsupported")
                    continue

            # Merge results per line
            # Might not need to merge results per line since the data is calculated using a left join on the truth.

            df = pd.read_csv(StringIO(result), names=['group', 'file', 'source', 'target'], na_values='None')
            df = df.convert_dtypes() # Forces pandas to use ints in source and target columns.
            df = df.drop_duplicates()

            if not len(df):
                print('No results generated. Verify decomposition results and paths.', file=sys.stderr)
                exit(1)

            df.to_csv(output_path, index=False)

if __name__ == "__main__":
    main()
