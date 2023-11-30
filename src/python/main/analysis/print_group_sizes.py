#!/usr/bin/env python3

"""
Print a summary of the size of groups per commit for each tool for each dataset.
"""

import argparse
import os
import sys

import pandas as pd

from concatenate_untangled_lines import concatenate_untangled_lines_for_dataset, column_names_dataset
from print_group_counts import prettify_summary

if __name__ == "__main__":
    main_parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    main_parser.add_argument(
        "--d4j",
        help="Folder containing the untangling results of D4J",
        metavar="PATH",
    )

    main_parser.add_argument(
        "--lltc4j",
        help="Folder containing the untangling results of LLTC4J",
        metavar="PATH",
    )
    
    args = main_parser.parse_args()

    dataset_name_map = {args.d4j: "Defects4J", args.lltc4j: "LLTC4J"}

    column_names_evaluation = ["dataset"] + column_names_dataset
    concatenate_df = pd.DataFrame(columns=column_names_evaluation)

    for dataset_dir in [args.d4j, args.lltc4j]:
        if dataset_dir is None:
            continue

        evaluation_path = os.path.join(dataset_dir, "evaluation")
        if not os.path.exists(evaluation_path):
            raise ValueError(f"Directory {evaluation_path} does not exist.")

        untangled_lines_dataset_df = concatenate_untangled_lines_for_dataset(evaluation_path)
        untangled_lines_dataset_df["dataset"] = dataset_name_map[dataset_dir]
        concatenate_df = pd.concat([concatenate_df, untangled_lines_dataset_df], ignore_index=True)

    group_size_df = concatenate_df.groupby(['dataset', 'project', 'bug_id', 'treatment', 'group']).size()

    # Group by 'treatment' and calculate summary statistics
    summary_df = group_size_df.groupby(['dataset', 'treatment']).agg(['min', 'max', 'median', 'std'])

    summary_df = prettify_summary(summary_df)

    print(summary_df.style
          .format(precision=0)
          .to_latex(multirow_align='t', clines="skip-last;data", hrules=True))
