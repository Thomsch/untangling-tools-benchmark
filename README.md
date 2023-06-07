# Untangling Tools Benchmark

Benchmark for comparing untangling tools on real bug-fixing commits.

## Requirements

- Python 3.8 is installed and on the PATH.
- Java 8 is installed and on the PATH.
- Java 11 is installed, but is not on the PATH.

## Installation

1. Clone this repository locally `git clone https://github.com/Thomsch/untangling-tools-benchmark`.
2. Go into the local repository folder `cd untangling-tools-benchmark`.
3. Create a virtual environment `python3 -m venv .venv`.
4. Activate the virtual environment `source .venv/bin/activate`.
5. Install Flexeme for Java
    1. Clone the Flexeme repository locally `git clone https://github.com/Thomsch/Flexeme ~/Flexeme`.
    2. Install Flexeme from the clone `pip install -e ~/Flexeme`.
6. Install local dependencies `pip install -r requirements.txt`.
7. Install Defects4J
    1. Clone the Defects4J locally `git clone https://github.com/rjust/defects4j ~/defects4j`.
    2. <Follow D4J instructions: set up Java 8, install dependencies, and run init.sh>.
    3. Export the `defects4j` command on your path `export PATH=$D4J_HOME/framework/bin:$PATH`.
8. Run `cp .env-template .env` and fill in the environment variables in `.env`:
    - `DEFECTS4J_HOME`: Location of the Defects4J installation (e.g., `~/defects4j`)
    - `JAVA_11`: Location of the **Java 11** executable to run SmartCommit. Requires Java 11. (e.g., `"$HOME/.sdkman/candidates/java/11.0.18-amzn/bin/java`")

## Usage
### Running the benchmark

Run `./evaluate_all.sh <bug-file> <out-dir>`.

- `<bug-file>` is a CSV file containing the list of bugs to evaluate. There are 2 pre-computed bug files that you can
  use (to generate a new bug file see **Generating the bug file** section):
    - `data/d4j-5-bugs.csv`: 5 bugs from the Defects4J project. Useful to test the benchmark end to end.
    - `data/d4j-compatible-bugs.csv`: All the Defects4J bugs that are compatible with the benchmark.
- `<out-dir>` is the directory where the repositories, decompositions, results, and logs will be stored.

For example, use `./evaluate_all.sh data/d4j-5-bugs.csv ~/benchmark` to run the evaluation on 5 bugs from the Defects4J
project.

#### Generating the bug file

You can generate a new bug file using `scripts/sample_bugs.sh data/d4j-compatible-bugs.csv <n>`, with `<n>`indicating
the number of bugs to include.

`data/d4j-compatible-bugs.csv` contains all the Defects4J bugs that are compatible with the benchmark (see **Limitations** sections).
It is generated from `data/d4j-bugs-all.csv` by removing manually all the bugs from the `Chart` project.
To generate `data/d4j-bugs-all.csv`, run `scripts/defects4j_bugs.sh > data/d4j-bugs-all.csv`.

### Untangling one Defects4J bug
If you only want to evaluate the decomposition of one Defects4J bug, you can run the following command: `./evaluate.sh <project> <bug-id> <out-dir> <repo-dir>`.
- This will run the decomposition evaluation on the specified Defects4J `<bug-id>` in `<project>`.
- `<out-dir>` will contain the results of the decomposition.
- `<repo-dir>` directory used by Defects4J to checkout the specified project.

### Aggregating decomposition elapsed time
Decompositions are timed. The result is stored for each tool and D4J bug (e.g., `benchmark/decomposition/flexeme/Csv_8/time.csv`).

To aggregated all the results in one file, run `scripts/aggregate_time.sh <out-dir>`.
- `<out-dir>` is the directory where the repositories, decompositions, results, and logs are stored.

## Adding an untangling tool

Add a call to your untangling tool executable in `evaluate.sh` and update `untangling_score.py`. Use the existing tools' code as a template.

## Limitations

- SmartCommit doesn't support SVN projects. For now, all commits in a SVN project are ignored by manually removing lines
  containing `Chart` in `out/commits.csv`.
- If the minimized Defects4J patch contains lines that are not in the original bug-fixing diff, these lines won't be counted as part of the bug-fix with respect to the original bug-fixing diff because they don't exist in that file.

## Ground truth

The ground truth is calculated from the original bug-fixing commit diff and the minimal bug inducing patch.
The ground truth excludes the following changes:

- Non-Java files
- Test files
- Comments
- Import statements
- Whitespaces (with `git diff -w`)
- Empty lines (in `ground_truth.py`)

## Manual analysis

1. Checkout D4J bug to analyse `defects4j checkout -p <project> -v <bug_id>b -w <repo_dir>`.
2. Open the diff for the bug `git diff -U0 <buggy-commit>^ <fixed-commit>`. (obtained from Defects4J's `active-bugs.csv`
   file)
3. In another tab, open the ground truth `less <out_dir>/evaluation/<project><bug_id>/truth.csv`
4. In another tab, open the Flexeme decomposition `less <out_dir>/evaluation/<project><bug_id>/flexeme.csv`.
5. In another tab, open the SmartCommit decomposition `less <out_dir>/evaluation/<project><bug_id>/truth.csv`.
6. Compare the decompositions with the ground truth, using the diff as reference for the changed content.