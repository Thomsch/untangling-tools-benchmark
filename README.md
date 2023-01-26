# Code Changes Benchmark
Scripts to run the code changes benchmark.

## Requirements
- `defects4j` is installed and on the PATH.
- `java` is installed and on the PATH.
- `python3` is installed and on the PATH.

### Environment Variables
- `DEFECTS4J_HOME`: Location of the defect4j installation.
- `JAVA_HOME`: Location of the java executable to run SmartCommit.

## Instructions
1. Run `scripts/active_bugs.sh > out/commits.csv`
2. Run `./evaluate_all.sh`. This script will run on a sample of the commits generated in the previous step.

Or run `make`.

### Aggregating decomposition elapsed time
All decomposition are timed. The result is stored in each decomposition folder.
To aggregated all of the results in one file, run `scripts/aggregate_time.sh`. 
It will create `out/time.csv` containing the runtime of each decomposition.

### Evaluate one bug
- Run `./evaluate.sh <project_id> <bug_id> <out_dir>`. E.g., `./evaluate.sh Lang 1 out/`.

## How the benchmark works
- `out/commit.csv` contains the commits in Defects4J. Generated by `./scripts/active_bugs.sh`.
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

### Improvements ideas
**TODO**
- Use Make to run the build pipeline.
    - The main benefit is that Make will take care of regenerating the correct files based on what is available / changed.

    - make: Use filename wildcard for each bug
    - rake has this options
