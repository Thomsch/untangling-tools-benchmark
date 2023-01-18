# Code Changes Benchmark
Scripts to run the code changes benchmark.

**TODO**
- Use Make to run the build pipeline.
    - The main benefit is that Make will take care of regenerating the correct files based on what is available / changed.

## Requirements
- `defects4j` is installed and on the PATH.
- `java` is installed and on the PATH.
- `python3` is installed and on the PATH.

### Environment Variables
- `DEFECTS4J_HOME`: Location of the defect4j installation.
- `JAVA_HOME`: Location of the java executable to run SmartCommit.

## How to
Evaluate decomposition:
- `./evaluate_decomposition.sh`
    - Checkout `./checkout_bug_fix.sh`
    - Decomposition `SmartCommit` + Retrieve changed lines > `out/evaluation/project/vid/groups.csv`
    - Decomposition `Flexeme`
    - Ground truth `./ground_truth.sh` > `out/evaluation/project/vid/truth.csv`
    - Metrics `./compute_metrics.py`

## How the benchmark works
- `out/commit.csv` contains the commits in Defects4J. Generated by `./scripts/active_bugs.csv`.
- Tools are running in parallel.
- Decomposition results outputs independently.
- Commits are checked out once since disk operations are a bottleneck
- All results are located in `./out`
    - `./out/decomposition/` contains the decomposition from different tools. Data directory.
    - `./out/evaluation/` contains the aggregated changed lines and ground truth
        - Organized per project / and bug id (vid). E.g., `./out/evaluation/<project>/<vid>`:
            - `./out/evaluation/<project>/<vid>/truth.csv`
            - `./out/evaluation/<project>/<vid>/approach1.csv`
            - `./out/evaluation/<project>/<vid>/approach2.csv`
    - `./out/results/` contains the aggregated results for the paper.

- Decomposition runs on a list of bugs.
    - Each bug runs all the approaches in parallel
    - Ground truth is run also calculated in parallel


I need:
- A script to run testing on one bug.
    - input: project and bug id
    - output: `./out/evaluation/<project>/<vid>`
    - steps
        1. Checkout bugid in temporary dictionary
        2. Calculate ground truth and output in ``./out/evaluation/<project>/<vid>/truth.csv`
        3. Decompose in parallel with each approach
        4. Collate results in `./out/evaluation/<project>/<vid>/<approach>.csv`
- A script going over all bugs
    - input: list of bugs
    - output: `./out/evaluation/<project>/<vid>`
- A script to run analysis
    - input: previous step
    - output: `./out/results/`

### Build system
- make: Use filename wildcard for each bug
- rake has this options