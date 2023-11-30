#!/usr/bin/env python3

"""
Print a summary of the size of groups per commit for each tool for each dataset.
"""

import argparse

from print_group_counts import prettify_summary, create_arg_parser, concatenate_datasets


def main(args: argparse.Namespace):
    """
    Implementation of the script's logic. See the script's documentation for details.
    """
    dataset_name_map = {args.d4j: "Defects4J", args.lltc4j: "LLTC4J"}
    concatenated_df = concatenate_datasets([args.d4j, args.lltc4j], dataset_name_map)

    group_size_df = concatenated_df.groupby(['dataset', 'project', 'bug_id', 'treatment', 'group']).size()

    # Group by 'treatment' and calculate summary statistics
    summary_df = group_size_df.groupby(['dataset', 'treatment']).agg(['min', 'max', 'median', 'std'])

    summary_df = prettify_summary(summary_df)

    print(summary_df.style
          .format(precision=0)
          .to_latex(multirow_align='t', clines="skip-last;data", hrules=True))

if __name__ == "__main__":
    main_parser = create_arg_parser()
    args = main_parser.parse_args()
    main(args)
