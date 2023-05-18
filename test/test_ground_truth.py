import unidiff

from src import ground_truth


def test_patch_line_is_updated():
    original_diff = unidiff.PatchSet.from_string("""
diff --git a/test/before.txt b/test/after.txt
index 8422d40..e2c9801 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,2 +1,4 @@
 A
+~
+E
 B""")
    patch_diff = unidiff.PatchSet.from_string("""
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..682191b 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -1,2 +1,3 @@
 A
+E
 B""")
    ground_truth.repair_line_numbers(patch_diff, original_diff)
    assert patch_diff[0][0][0].target_line_no == 1  # First line (A) is unchanged
    assert patch_diff[0][0][1].target_line_no == 3  # E is inserted after A on line 3 in the original patch
    assert patch_diff[0][0][2].target_line_no == 3  # Third line (B) is unchanged


def test_duplicate_lines_are_updated():
    original_diff = unidiff.PatchSet.from_string("""
diff --git a/test/before.txt b/test/after.txt
index 8422d40..fb47f45 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,4 +1,14 @@
 A
+~
+~
+~
+~
+E
+F
 B
 C
+E
+F
+G
 D
+H
""")
    patch_diff = unidiff.PatchSet.from_string("""
diff --git a/test/before.txt b/test/patch.txt
index 8422d40..3e8a10f 100644
--- a/test/before.txt
+++ b/test/patch.txt
@@ -1,4 +1,6 @@
 A
+E
 B
 C
+E
 D""")

    ground_truth.repair_line_numbers(patch_diff, original_diff)
    assert len(patch_diff[0][0]) == 6  # Patch doesn't change in size
    assert patch_diff[0][0][0].target_line_no == 1  # First line (A) is unchanged
    assert patch_diff[0][0][1].target_line_no == 6  # E is inserted after A on line 6 in the original patch
    assert patch_diff[0][0][2].target_line_no == 3  # Third line (B) is unchanged
    assert patch_diff[0][0][3].target_line_no == 4  # Fourth line (C) is unchanged
    assert patch_diff[0][0][4].target_line_no == 10  # E is inserted after C on line 10 in the original patch
    assert patch_diff[0][0][5].target_line_no == 6  # Sixth line (D) is unchanged


def test_get_line_map():
    diff = unidiff.PatchSet.from_string("""
diff --git a/test/before.txt b/test/after.txt
index 8422d40..71040ea 100644
--- a/test/before.txt
+++ b/test/after.txt
@@ -1,4 +1,10 @@
 A
+E
+F
 B
 C
+E
+F
+G
 D
+H
""")
    line_map = ground_truth.get_line_map(diff)
    e_changes = line_map['+E\n']
    assert len(e_changes) == 2
    assert e_changes[0][2] == 2
    assert e_changes[1][2] == 6
