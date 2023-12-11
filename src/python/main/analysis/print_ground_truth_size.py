"""
Prints the ground truth sizes for each dataset as Latex commands in stdout.
"""
import sys
import os

sys.path.insert(1, os.path.join(sys.path[0], '..'))
import metrics
import evaluation_results
import argparse

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def main(d4j_ground_truth_file: str, lltc4j_ground_truth_file: str):
    d4j_ground_truth = evaluation_results.read_ground_truth(d4j_ground_truth_file)
    lltc4j_ground_truth = evaluation_results.read_ground_truth(lltc4j_ground_truth_file)

    df1 = metrics.calculate_ground_truth_size_per_commit(d4j_ground_truth)
    df1['dataset'] = 'Defects4J'

    df2 = metrics.calculate_ground_truth_size_per_commit(lltc4j_ground_truth)
    df2['dataset'] = 'LLTC4J'

    result_df = pd.concat([df1, df2], ignore_index=True)[['count', 'dataset']]

    # print(result_df)
    # sns.histplot(result_df, x='count', hue='dataset', log_scale=True, element="step", fill=True)
    # plt.savefig('ground_truth_size.png')

    mean_df = result_df[['dataset', 'count']].groupby('dataset').agg(['mean', 'std']).round(2)


    for index, row in mean_df.iterrows():
        dataset_name_for_latex = index.lower().replace('4', 'f')
        print(f"\\newcommand\\{dataset_name_for_latex}MeanSize{{{row['count']['mean']}\\xspace}}")
        print(f"\\newcommand\\{dataset_name_for_latex}StdSize{{{row['count']['std']}\\xspace}}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=sys.argv[0],
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--d4j-ground-truth",
        help="Path to the ground truth file containing all Defects4J commits",
        required=True,
        metavar="D4J_GROUND_TRUTH_FILE",
    )

    parser.add_argument(
        "--lltc4j-ground-truth",
        help="Path to the ground truth file containing all LLTC4J commits",
        required=True,
        metavar="LLTC4J_GROUND_TRUTH_FILE",
    )

    args = parser.parse_args()
    main(args.d4j_ground_truth, args.lltc4j_ground_truth)


