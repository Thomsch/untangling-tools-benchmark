"""
Test for the print_tangled_levels script.
"""


def test_count_tangled_metrics():
    """
    Test the count_tangled_metrics function.
    """
    #
    # data = [
    #     ["d1", "a", 2, 4, 5, 6, 7],
    #     ["d1", "b", 1, 0, 4, 2, 1],
    #     ["d1", "c", 0, 0, 0, 0, 0],
    #     ["d2", "z", 1, 0, 0, 0, 0],
    # ]
    # df = pd.DataFrame(
    #     data,
    #     columns=[
    #         "dataset",
    #         "vid",
    #         "tangled_lines_count",
    #         "tangled_hunks_count",
    #         "tangled_files_count",
    #         "is_tangled_patch",
    #         "single_concern_patches_count",
    #     ],
    # )
    #
    # df_aggregated = count_tangled_levels(df)
    #
    # print(df_aggregated.to_string())
    #
    # assert df_aggregated.loc["d1", "tangled_lines_count"] == 2
    # assert df_aggregated.loc["d1", "tangled_hunks_count"] == 1
    # assert df_aggregated.loc["d1", "tangled_files_count"] == 2
    # assert df_aggregated.loc["d1", "tangled_patches_count"] == 2
    # assert df_aggregated.loc["d1", "single_concern_patches_count"] == 2
    #
    # assert df_aggregated.loc["d2", "tangled_lines_count"] == 1
    # assert df_aggregated.loc["d2", "tangled_hunks_count"] == 0
    # assert df_aggregated.loc["d2", "tangled_files_count"] == 0
    # assert df_aggregated.loc["d2", "tangled_patches_count"] == 0
    # assert df_aggregated.loc["d2", "single_concern_patches_count"] == 0
