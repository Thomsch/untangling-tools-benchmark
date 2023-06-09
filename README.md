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
   1. Clone the Flexeme repository locally `git clone https://github.com/Thomsch/Flexeme ~/Flexeme`.
   2. Install Graphviz https://graphviz.org/.
   3. Install Flexeme from the clone `pip install -e ~/Flexeme`
      - If the dependency `pygraphviz` fails to install. Visit https://pygraphviz.github.io/documentation/stable/install.html and follow the instructions for your OS.
6. Install local dependencies `pip install -r requirements.txt`.
7. Install Defects4J
    1. Clone the Defects4J locally `git clone https://github.com/rjust/defects4j ~/defects4j`.
    2. <Follow D4J instructions: set up Java 8, install dependencies, and run init.sh>.
    3. Export the `defects4j` command on your path `export PATH=$D4J_HOME/framework/bin:$PATH`.
8. Run `cp .env-template .env` and fill in the environment variables in `.env`:
    - `DEFECTS4J_HOME`: Location of the Defects4J installation (e.g., `~/defects4j`)
    - `JAVA_11`: Location of the **Java 11** executable to run SmartCommit and Flexeme. Requires Java 11. (e.g., `"$HOME/.sdkman/candidates/java/11.0.18-amzn/bin/java`")
9. Install GNU coreutils if you are on MacOS or Windows.

## Terminology
- Program diff: The diff between the buggy and fixed version in the VCS
- Minimal bug fixing diff: The minmal diff that fixes the bug. It is calculated by inverting the Defects4J minimal bug-inducing patch  
- Non-bug fixing diff: The diff between buggy and fixed version that is not part of the minimal bug fixing diff

If you encounter a term in the documentation or the source code that is not defined here, please open an issue. Thank you!

## Usage
### Running the benchmark

Run `./evaluate_all.sh <bug-file> <out-dir>`.

- `<bug-file>` is a CSV file containing the list of bugs to evaluate. There are 2 pre-computed bug files that you can
  use (to generate a new bug file see **Generating the bug file** section):
    - `data/d4j-5-bugs.csv`: 5 bugs from the Defects4J project. Useful to test the benchmark end to end
    - `data/d4j-compatible-bugs.csv`: All the Defects4J bugs that are compatible with the benchmark
- `<out-dir>` is the directory where the repositories, decompositions, results, and logs will be stored

For example, use `./evaluate_all.sh data/d4j-5-bugs.csv ~/benchmark` to run the evaluation on 5 bugs from the Defects4J
project.

The results will be stored in `<out-dir>` (e.g., `~/benchmark`):
- `<out-dir>/decomposition/`: Folder containing the output of the decomposition tools. Each tool has its own sub-folder
- `<out-dir>/evaluation/`: Folder containing the decomposition results. Each bug has its own sub-folder and contains the following:
  - `truth.csv`: The ground truth of the bug-fixing commit. For each changed line whether it's a bug-fixing change or not.
  - `smartcommit.csv`: The decomposition results of SmartCommit in CSV format. Each line correspond to a changed line and its associated group
  - `flexeme.csv`: The decomposition results of Flexeme in CSV format. Each line correspond to a changed line and its associated group
  - `file_untangling.csv`: The decomposition results of file-based untangling in CSV format. Each line correspond to a changed line and its associated group
  - `scores.csv`: The rand index score for each tool. CSV columns are d4j_project,d4j_bug_id,smartcommit_score,flexeme_score,file_untangling_score
- `<out-dir>/logs/`: Folder containing the logs of the `evalute.sh` script
- `<out-dir>/repositories/`: Folder containing the checked out Defect4J bug repositories
- `<out-dir>/metrics/`: Folder containing metrics for each Defects4J bug
- `decompositions.csv`: Aggregated decomposition scores across all the D4J bugs evaluated. CSV columns are d4j_project,d4j_bug_id,smartcommit_score,flexeme_score,file_untangling_score
- `metrics.csv`: Aggregated metrics across all the D4J bugs evaluated

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

## Tests
- Python tests are located in the `test` folder. To run the tests, run `pytest test`.
- Run `make check` to run all the checks (tests, linting, etc.) for bash and Python.

Help with adding more automated tests is welcome! :)

## Adding an untangling tool

Add a call to your untangling tool executable in `evaluate.sh` and update `untangling_score.py`. Use the existing tools' code as a template.

## Limitations

- SmartCommit doesn't support SVN projects. For now, all commits in a SVN project are ignored by manually removing lines
  containing `Chart` in `out/commits.csv`.
- If the minimized Defects4J patch contains lines that are not in the original bug-fixing diff, these lines won't be counted as part of the bug-fix with respect to the original bug-fixing diff because they don't exist in that file.

## Structure & repository-specific files
- `analysis/`: Scripts to analyse the results
- `bin/`: Contains binaries of untangling tools (when applicable)
- `data/`: Contains list of Defects4J bugs to run the benchmark on
- `scripts/`: Utility Bash scripts to run the benchmark
- `src/`: Utility Python scripts to run the benchmark
- `test/`: Python tests
- `.env-template`: Template for the `.env` file containing computer-specific environment variables and paths
- `conftest.py`: Pytest configuration
- `evaluate.sh`: Script to run the benchmark on one Defects4J bug
- `evaluate_all.sh`: Script to run the benchmark for a list of Defects4J bugs
- `generate_all.sh` [WIP]: Script to only generate the ground truth for a list of Defects4J bugs
- `generate_ground_truth.sh` [WIP]: Script to generate different versions of the ground truth per Defects4J bug

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
