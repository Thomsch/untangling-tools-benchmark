# Code Changes Benchmark
Scripts to run the code changes benchmark.

**TODO**
- Use Make to run the build pipeline.
    - The main benefit is that Make will take care of regenerating the correct files based on what is available / changed.

## Requirements
- `defects4j` is installed and on the PATH.

## How to

Evaluate decomposition:
- `./evaluate_decomposition.sh`
    - Checkout `./checkout_bug_fix.sh`
    - Decomposition `SmartCommit` + Retrieve changed lines > `out/evaluation/project/vid/groups.csv`
    - Decomposition `Flexeme`
    - Ground truth `./ground_truth.sh` > `out/evaluation/project/vid/truth.csv`
    - Metrics `./compute_metrics.py`
