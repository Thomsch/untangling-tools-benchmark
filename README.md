# Untangling Tools Benchmark

Benchmark for comparing untangling tools on real bug-fixing commits.

## Requirements

- Python 3.8.15 is installed and on the PATH.  (Flexeme requires exactly this version.)
- Java 8 is installed and on the PATH.
- Java 11 is installed, but is not on the PATH.

## Installation

1. Clone this repository locally `git clone https://github.com/Thomsch/untangling-tools-benchmark`.
2. Go into the local repository folder `cd untangling-tools-benchmark`.
3. Create a virtual environment `python3 -m venv .venv`.
4. Activate the virtual environment `source .venv/bin/activate`.
5. Install Flexeme for Java
   1. Clone the Flexeme repository locally `git clone https://github.com/Thomsch/Flexeme ../Flexeme`.
   2. Install Graphviz https://graphviz.org/.
   3. Install Flexeme from the clone `pip install -e ../Flexeme`
      - If the dependency `pygraphviz` fails to install. Visit https://pygraphviz.github.io/documentation/stable/install.html and follow the instructions for your OS.
6. Install local dependencies `pip install -U -r requirements.txt`.
7. [Install Defects4J](https://github.com/rjust/defects4j#setting-up-defects4j)
8. Run `cp .env-template .env` and fill in the environment variables in `.env`:
    - `DEFECTS4J_HOME`: Location of the Defects4J installation (e.g., `~/defects4j`)
    - `JAVA_11`: Location of the **Java 11** executable to run SmartCommit and Flexeme. Requires Java 11. (e.g., `"$HOME/.sdkman/candidates/java/11.0.18-amzn/bin/java`")
9. Install GNU coreutils if you are on MacOS or Windows.

## Terminology
- Program diff: The diff between the buggy and fixed version in the VCS
- Minimal bug fixing diff: The minmal diff that fixes the bug. It is calculated by inverting the Defects4J minimal bug-inducing patch  
- Non-bug fixing diff: The diff between buggy and fixed version that is not part of the minimal bug fixing diff

The detailed description of these artifacts are listed in [diagrams/README.md](diagrams/README.md).

If you encounter a term in the documentation or the source code that is not defined here, please open an issue. Thank you!

## Usage
### Running the benchmark
For visualization purpose, here is the [pipeline](diagrams/pipeline.drawio.svg) for evaluation framework in `/evaluate.sh`.

Run `./evaluate_all.sh <bug-file> $UTB_OUTPUT`.

- `<bug-file>` is a CSV file containing the list of bugs to evaluate. There are 2 pre-computed bug files that you can
  use (to generate a new bug file see **Generating the bug file** section):
    - `data/d4j-5-bugs.csv`: 5 bugs from the Defects4J project. Useful to test the benchmark end to end.  You can generate a new bug file using `scripts/sample_bugs.sh data/d4j-compatible-bugs.csv <n>`, with `<n>`indicating the number of bugs to include.
    - `data/d4j-compatible-bugs.csv`: All the Defects4J bugs that are compatible with the benchmark.
      (see **Limitations** section).
      It is generated from `data/d4j-bugs-all.csv` by removing manually all the bugs from the `Chart` project.
    - `data/d4j-bugs-all.csv`: All the Defects4J bugs.  To generate, run `scripts/defects4j_bugs.sh > data/d4j-bugs-all.csv`.
- `$UTB_OUTPUT` is the output directory where the repositories, decompositions, results, and logs will be stored. You can set it to any directory you want (e.g., `~/benchmark`). 

For example, use `./evaluate_all.sh data/d4j-5-bugs.csv $UTB_OUTPUT` to run the evaluation on 5 bugs from the Defects4J
project.

The results will be stored in `$UTB_OUTPUT`:
- `$UTB_OUTPUT/decomposition/`: Folder containing the output of the decomposition tools. Each tool has its own sub-folder
- `$UTB_OUTPUT/decomposition/<toolname>/<project_id>/time.csv  The time for the given tool to process the given bug.
  To aggregate all the results in one file, run `scripts/aggregate_time.sh <out-dir>`.
- `$UTB_OUTPUT/evaluation/`: Folder containing the decomposition results. Each bug has its own sub-folder and contains the following:
  - `truth.csv`: The ground truth of the bug-fixing commit. We define a changed line as either a line removed from the original (buggy) file (-) or a line added to the modified (fixed) file (+). Each changed line is assigned one of three groups: 'fix' (a bug-fixing line), 'other' (a non-bug-fixing line), or 'both' (a tangled line). The file has a CSV header.
  - `smartcommit.csv`: The decomposition results of SmartCommit in CSV format. Each line corresponds to a changed line and its associated group. The file has a CSV header.
  - `flexeme.csv`: The decomposition results of Flexeme in CSV format. Each line corresponds to a changed line and its associated group. The file has a CSV header.
  - `file_untangling.csv`: The decomposition results of file-based untangling in CSV format. Each line corresponds to a changed line and its associated group. The file has a CSV header.
  - `scores.csv`: The rand index score for each tool. The file has no CSV header. The columns are d4j_project,d4j_bug_id,smartcommit_score,flexeme_score,file_untangling_score
- `$UTB_OUTPUT/logs/`: Folder containing the logs of the `evalute.sh` script
- `$UTB_OUTPUT/repositories/`: Folder containing the checked out Defect4J bug repositories
- `$UTB_OUTPUT/metrics/`: Folder containing metrics for each Defects4J bug. See section [Metrics](#metrics) for more details.
- `decomposition_scores.csv`: Decomposition scores for each D4J bug evaluated. The file has no CSV header. The columns are d4j_project,d4j_bug_id,smartcommit_score,flexeme_score,file_untangling_score.
- `metrics.csv`: Aggregated metrics across all the D4J bugs evaluated. The file has no CSV header. The columns are d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated.


#### Generating the bug file

### Untangling one Defects4J bug
If you only want to evaluate the decomposition of one Defects4J bug, you can run the following command: `./evaluate.sh <project> <bug-id> $UTB_OUTPUT <repo-dir>`.
- This will run the decomposition evaluation on the specified Defects4J `<bug-id>` in `<project>`.
- `$UTB_OUTPUT` will contain the results of the decomposition.
- `<repo-dir>` directory used by Defects4J to checkout the specified project.

### Aggregating decomposition elapsed time

## Tests
- Run `make check` to run all the checks (tests, linting, etc.) for bash and Python.

Help with adding more automated tests is welcome! :)

## Adding an untangling tool

Add a call to your untangling tool executable in `evaluate.sh` and update `untangling_score.py`. Use the existing tools' code as a template.

## Limitations

- SmartCommit doesn't support SVN projects. All commits in a SVN project are ignored by manually removing lines
  containing `Chart` in `data/d4j-bugs-all`.
- If the minimized Defects4J patch contains lines that are not in the original bug-fixing diff, these lines won't be counted as part of the bug-fix with respect to the original bug-fixing diff because they don't exist in that file. This could indicate either a mistake in Defects4J or a tangled line. If the line is a labelling mistake in Defects4J, an issue is opened in the Defects4J repository.

## Directory structure
- `analysis/`: Scripts to analyse the results. The .ipynb files are all for one-off experiments and are not part of any pipeline.
- `bin/`: Contains binaries of untangling tools (when applicable)
- `data/`: Contains list of Defects4J bugs to run the benchmark on
- `src/`: Python scripts to run the benchmark
  - `python/`: Python files
    - `main/`: Python source code for the benchmark
    - `test/`: Python tests
  - `bash/`: Bash files
    - `main/`: Bash source code for the benchmark
- `.env-template`: Template for the `.env` file containing computer-specific environment variables and paths
- `conftest.py`: Pytest configuration
- `evaluate.sh`: Script to run the benchmark on one Defects4J bug
- `evaluate_all.sh`: Script to run the benchmark for a list of Defects4J bugs
- `generate_all.sh` [WIP]: Script to only generate the ground truth for a list of Defects4J bugs
- `generate_ground_truth.sh` [WIP]: Script to generate different versions of the ground truth per Defects4J bug

## Ground truth

The ground truth is calculated from the original bug-fixing commit diff and the minimal bug inducing patch.

For visualization purpose, here is the [diagram](diagrams/diffs.drawio.svg) for ground truth construction.

## Metrics

Commit metrics are calculated by `src/commit_metrics.py` and stored in `<out_dir>/metrics/`.
The supported metrics are:
  - Total number of files updated (i.e. both code and test files)
  - Number of test files updated 
  - Number of hunks 
  - Average hunk size 
  - Number of lines changed (i.e. all lines with +/- indicators in the original diff generated from pre-fix and post-fix versions).

## Manual analysis

1. Checkout D4J bug to analyse `defects4j checkout -p <project> -v <bug_id>b -w <repo_dir>`.
2. Open the diff for the bug `git diff -U0 <buggy-commit>^ <fixed-commit>`. (obtained from Defects4J's `active-bugs.csv`
   file)
3. In another tab, open the ground truth `less $UTB_OUTPUT/evaluation/<project><bug_id>/truth.csv`
4. In another tab, open the Flexeme decomposition `less $UTB_OUTPUT/evaluation/<project><bug_id>/flexeme.csv`.
5. In another tab, open the SmartCommit decomposition `less $UTB_OUTPUT/evaluation/<project><bug_id>/truth.csv`.
6. Compare the decompositions with the ground truth, using the diff as reference for the changed content.
