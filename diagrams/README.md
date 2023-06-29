### Ground truth Diagram
The ground truth excludes the following changes:
- Non-Java files
- Test files
- Comments
- Import statements
- Whitespace (with `git diff -w`)
- Empty lines (in `ground_truth.py`)
When all these changes are excluded, we say that a file is "filtered".

The procedure to create ground truth is illustrated below. The diagram is created with [draw.io](https://app.diagrams.net/). The draw.io extensions in VSCode allows for more functionality when streamlined with Git.

### Terminology
There are 3 code artifacts and 3 diff artifacts.

The code artifacts are (they are orange and yellow rectangular boxes on the left of the diagram below):
* V_{n-1}, the buggy code from the version control repository
* V_bug, the buggy code with all non-bug-fixing changes applied
* V_fixed = V_n, the fixed code from the version control repository

The diff artifacts are:
* Version Control Diff (or original diff or programmer diff): The diff between V_{n-1} and V_n. This diff file is not filtered. 
* Bug-Fix Diff (or minimal diff): The diff between V_bug and V_fixed. This contains all bug-fixing lines and is the inverse of the Defects4J bug-inducing patch (which is the diff between V_fixed and V_bug). The line numbers of Bug-Fix Diff are repaired to match exactly with the Original Diff. This diff file is not filtered.
    - Note: the Bug-Fix Diff might not be a subset of Original Diff, as it may contain bug-fix portion of a tangled line (e.g. (4 + F)) - these are dropped when creating the ground truth. 
* Non-Bug-Fix Diff: The diff between V_{n-1} and V_bug.
    - Current implementation: The set difference {Orginal Diff \ Bug-Fix Diff} - which contains all the lines that are non-bug-fixing and tangled (as we drop bug-fix portions in ground truth). This diff file is not filtered.
    - Desired implementation: The UNIX diff of {buggy version, fixed version}, in which the fixed code is bug-fix-diff applied on original-diff (Original_diff(buggy) + Bug-fix_diff). We expect that this file contains only the non-bug-fixing portion of a tangled line and is filtered.

### Diagram legend
- Orange boxes: Different source code versions in the Version Control history.
- Yellow boxes: Different source code versions provided by Defects4J.
- Blue rectangles: UNIX Diff format files that are converted into PatchSet Objects. In the program, we utilize OOP provided by the `unidiff` package by treating Diffs as PatchFiles - i.e. containing PatchSet, diff Line, etc. Objects. 
- Tables: DataFrames. To manipulate the diff PatchSets more easily, we finally convert the filtered PatchSets to DataFrame formats/CSV exports for empirical analysis in the succeeding steps of the evaluation framework. When a PatchSet is converted into a DataFrame, it is filtered.
- Green rounded boxes: the hashtagged (#) labels are actual names of code files/function calls/bash scripts, etc. that are invoked to produce the output indicated by the arrow. If the draw.io VSCode extension is installed with Code Links enabled, double-clicking on the hashtag allows for a workspace search for a symbol matching the rest of the label.


![Ground truth](./diffs.drawio.svg)

## Evaluation Pipeline
The diagram illustrates the evaluation pipeline implemented in the `evaluate.sh` script.

![Evaluation Pipeline](./pipeline.drawio.svg)
