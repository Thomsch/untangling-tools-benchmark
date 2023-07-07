import unidiff
from src.python.main import ground_truth

def test_non_overlap_lines_correctly_labelled():
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
    labels = ground_truth.tag_truth_label(original_diff, fix_diff, nonfix_diff)
    assert labels[0] == 'other'
    assert labels[1] == 'fix'

def test_overlap_lines_correctly_labelled():
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

    labels = ground_truth.tag_truth_label(original_diff, fix_diff, nonfix_diff)
    assert labels[0] == 'fix'
    assert labels[1] == 'fix'
    assert labels[2] == 'fix'
    assert labels[3] == 'other'
    assert labels[4] == 'other'
    assert labels[5] == 'other'
    assert labels[6] == 'fix'
    assert labels[7] == 'other'
    assert labels[8] == 'other'
    assert labels[9] == 'other'