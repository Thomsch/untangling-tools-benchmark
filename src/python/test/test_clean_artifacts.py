"""
Tests for the clean_artifacts module.
"""
from unidiff import (
    PatchSet,
    LINE_TYPE_CONTEXT,
    LINE_TYPE_ADDED,
)
from src.python.main import clean_artifacts


def test_cancelled_out_lines_are_removed():
    """
    Test that consecutive lines that cancel each other out are removed in patch.
    """
    original_patch = PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/after.txt
index 8422d40..e2c9801 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,3 +1,3 @@
 A
-E
+E
 B"""
    )
    clean_patch = clean_artifacts.cancel_out_diff(original_patch)
    assert len(clean_patch) == 1
    assert len(clean_patch[0]) == 1
    assert len(clean_patch[0][0]) == 4
    # assert clean_patch[0][0][1].line_type == LINE_TYPE_CONTEXT
    assert clean_patch[0][0][1].value.strip() == ""
    # assert clean_patch[0][0][2].line_type == LINE_TYPE_CONTEXT
    assert clean_patch[0][0][2].value.strip() == ""
    return clean_patch


def test_identical_line_contents():
    """
    Test that consecutive lines that cancel each other out are removed in patch.
    """
    original_patch = PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/after.txt
index 8422d40..fb47f45 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,7 +1,12 @@
 A
 ~
-~
+~
+~
-F
+F
 B
 C
+E
+F
+G
 D
+D
"""
    )
    clean_patch = clean_artifacts.cancel_out_diff(original_patch)
    assert len(clean_patch) == 1
    assert len(clean_patch[0]) == 1
    assert len(clean_patch[0][0]) == 14
    assert clean_patch[0][0][-1].line_type == LINE_TYPE_ADDED
    assert clean_patch[0][0][-2].line_type == LINE_TYPE_CONTEXT
    # assert clean_patch[0][0][2].line_type == LINE_TYPE_CONTEXT
    assert clean_patch[0][0][2].value.strip() == ""
    # assert clean_patch[0][0][3].line_type == LINE_TYPE_CONTEXT
    assert clean_patch[0][0][3].value.strip() == ""
    # assert clean_patch[0][0][5].line_type == LINE_TYPE_CONTEXT
    assert clean_patch[0][0][5].value.strip() == ""
    # assert clean_patch[0][0][6].line_type == LINE_TYPE_CONTEXT
    assert clean_patch[0][0][6].value.strip() == ""
    return clean_patch


def test_fix_short_hunk_info():
    """
    Test that hunk info is fixed when lines are filtered.
    """
    clean_patch = test_cancelled_out_lines_are_removed()
    fixed_patch = clean_artifacts.fix_hunk_info(clean_patch)
    assert fixed_patch[0][0].source_length == 3
    assert fixed_patch[0][0].target_length == 3


def test_fix_long_hunk_info():
    """
    Test that hunk info is fixed when lines are filtered.
    """
    clean_patch = test_identical_line_contents()
    fixed_patch = clean_artifacts.fix_hunk_info(clean_patch)
    assert fixed_patch[0][0].source_length == 7
    assert fixed_patch[0][0].target_length == 12
