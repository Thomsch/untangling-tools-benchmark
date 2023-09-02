"""
Test the ground truth module.
"""
import unidiff
from src.python.main import ground_truth


def test_non_overlap_lines_correctly_labelled():
    """
    Test that the truth group of each line in VC diff is correctly labelled.
    """
    original_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/after.txt
index 8422d40..e2c9801 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,2 +1,4 @@
 A
+~
+E
 B"""
    )
    fix_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..682191b 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -1,2 +1,3 @@
 A

+E
 B"""
    )
    nonfix_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..682191b 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -2,0 +2,1 @@
+~
"""
    )
    ground_truth_df = ground_truth.classify_diff_lines(
        original_diff, fix_diff, nonfix_diff
    )
    assert ground_truth_df.iloc[0]["group"] == "other"  # + ~ is a nonfix
    assert ground_truth_df.iloc[1]["group"] == "fix"  # + E is a fix


def test_overlap_lines_correctly_labelled():
    """
    Test that the truth group of each line in VC diff is correctly
    labelled, even when they overlap in content.
    """
    original_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/after.txt
index 8422d40..fb47f45 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,4 +1,14 @@
 A
+~~
+~
+E
+//
+~~
+F
 B
 C
+E
+F
+G
 D
+H
"""
    )
    fix_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..3e8a10f 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -1,1 +1,4 @@
 A
+~~
+~
+E
@@ -10,0 +10,1 @@
+E
"""
    )
    nonfix_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..682191b 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -1,2 +1,5 @@
+//
+~~
+F
 B
 C
@@ -1,1 +7,4 @@
+F
+G
 D
+H
"""
    )

    ground_truth_df = ground_truth.classify_diff_lines(
        original_diff, fix_diff, nonfix_diff
    )
    assert ground_truth_df.iloc[0]["group"] == "fix"  # + ~~ is a fix
    assert ground_truth_df.iloc[1]["group"] == "fix"  # + ~ is a fix
    assert ground_truth_df.iloc[2]["group"] == "fix"  # + E is a fix
    assert ground_truth_df.iloc[3]["group"] == "other"  # + // is a nonfix
    assert ground_truth_df.iloc[4]["group"] == "other"  # + ~~ is a nonfix
    assert ground_truth_df.iloc[5]["group"] == "other"  # + F is a fix
    assert ground_truth_df.iloc[6]["group"] == "fix"  # + E is a fix
    assert ground_truth_df.iloc[7]["group"] == "other"  # + F is a nonfix
    assert ground_truth_df.iloc[8]["group"] == "other"  # + G is a nonfix
    assert ground_truth_df.iloc[9]["group"] == "other"  # + D is a nonfix


def test_tangled_both_label_correctly_tagged():
    """
    Test that the truth group of each line in VC diff is correctly
    labelled, even when they overlap in content.
    """
    original_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/after.txt
index 8422d40..e2c9801 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,2 +1,2 @@
- a = 3
+ b = 4
 B"""
    )
    nonfix_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..682191b 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -1,2 +1,2 @@
- a = 3
+ b = 3
 B"""
    )
    fix_diff = unidiff.PatchSet.from_string(
        """
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..682191b 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -1,1 +1,1 @@
- b = 3
+ b = 4
"""
    )
    ground_truth_df = ground_truth.classify_diff_lines(
        original_diff, fix_diff, nonfix_diff
    )
    assert (
        ground_truth_df.iloc[0]["group"] == "other"
    )  # - a = 3 is a nonfix: it is part of a variable renaming
    assert ground_truth_df.iloc[1]["group"] == "fix"
    assert ground_truth_df.iloc[2]["group"] == "other"
    # + b = 4 is tangled: contains both a fix and a variable renaming
