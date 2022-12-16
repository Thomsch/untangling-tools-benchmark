# Code Changes Benchmark
Scripts to run the code changes benchmark.

**TODO**
- Use Make to run the build pipeline.
    - The main benefit is that Make will take care of regenerating the correct files based on what is available / changed.

## Requirements
- `defects4j` is installed and on the PATH.

## How to
1. Decompose changes using SmartCommit (result in `out/smartcommit/project/commit`)
    1. Checkout repository from Defect4J
    2. Run decomposition
2. Retrieve ground truth (result in `out/evaluation/project/bug_id/truth.csv`)
3. Retrieve groups changed lines (result in `out/evaluation/project/bug_id/groups.csv`)
