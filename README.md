# Untangling Tools Evaluation Infrastructure

Experimental infrastructure for comparing untangling tools on real bug-fixing commits.

## Requirements

- Python 3 is installed and on the PATH.
- Java 8 is installed and on the PATH.
- Java 11 is installed, but is not on the PATH.

## Installation

1.

```
git clone https://github.com/Thomsch/untangling-tools-benchmark
cd untangling-tools-benchmark
python3 -m venv .venv
source .venv/bin/activate
pip install -U -r requirements.txt
```

2. Install Graphviz https://graphviz.org/.  On Debian or Ubuntu: `sudo apt install graphviz`
3. Install Flexeme for Java

```
git clone https://github.com/Thomsch/Flexeme ../Flexeme
pip install -e ../Flexeme
```

If the dependency `pygraphviz` fails to install. Visit https://pygraphviz.github.io/documentation/stable/install.html and follow the instructions for your OS.

4. [Install Defects4J](https://github.com/rjust/defects4j#setting-up-defects4j)
5. Install GNU coreutils if you are on MacOS or Windows.
6. Install [GNU Parallel](https://www.gnu.org/software/parallel/).
   For Ubuntu:

```
PARALLEL_DEB=parallel_20230622_all.deb
wget https://download.opensuse.org/repositories/home:/tange/xUbuntu_22.04/all/${PARALLEL_DEB}
sudo dpkg -i ${PARALLEL_DEB}
mkdir ${HOME}/.parallel
touch ${HOME}/.parallel will-cite
```

7. Run `cp .env-template .env` and fill in the environment variables in `.env`:
    - `DEFECTS4J_HOME`: Location of the Defects4J installation (e.g., `~/defects4j`)
    - `JAVA11_HOME`: Location of the **Java 11** home to run SmartCommit and Flexeme. (e.g., `"$HOME/.sdkman/candidates/java/11.0.18-amzn`")

## Terminology
- Program diff: The diff between the buggy and fixed version in the VCS
- Minimal bug fixing diff: The minmal diff that fixes the bug. It is calculated by inverting the Defects4J minimal bug-inducing patch  
- Non-bug fixing diff: The diff between buggy and fixed version that is not part of the minimal bug fixing diff

The detailed description of these artifacts are listed in [diagrams/README.md](diagrams/README.md).

If you encounter a term in the documentation or the source code that is not defined here, please open an issue. Thank you!

## Usage
### Running the evaluation
The evaluation run the untangling tools on a list of Defects4J bugs and compute the untangling performance of the tools. It is composed of 3 steps.

For example, to run the evaluation on the Defects4J bugs in `data/d4j-5-bugs.csv`, run the following scripts in order:

1. `./decompose.sh data/d4j-5-bugs.csv $UTB_OUTPUT`. Run the untangling tools to obtain the decompositions
   - `$UTB_OUTPUT` is the output directory where the repositories, decompositions, results, and logs will be stored. You can set it to any directory you want (e.g., `~/untangling-evaluation`). 
2. `./generate_ground_truth.sh data/d4j-5-bugs.csv $UTB_OUTPUT`. Generate the ground truth from the Defects4J manual patches
3. `./score.sh data/d4j-5-bugs.csv $UTB_OUTPUT`. Compute the untangling performance of the tools. (Depends on the previous steps).

All results will be stored in `$UTB_OUTPUT`:
- `$UTB_OUTPUT/decomposition/`: Folder containing the output of the decomposition tools. Each tool has its own sub-folder
- `$UTB_OUTPUT/decomposition/<toolname>/<project_id>/time.csv  The time for the given tool to process the given bug.
  To aggregate all the results in one file, run `scripts/aggregate_time.sh <out-dir>`.
- `$UTB_OUTPUT/evaluation/`: Folder containing the decomposition results. Each bug has its own sub-folder and contains the following:
  - `truth.csv`: The ground truth of the bug-fixing commit. We define a changed line as a line from the diff from the buggy to the fixed version in CSV. The changed line can be a deletion or addition. Each changed line is assigned one of three groups: 'fix' (a bug-fixing line), 'other' (a non-bug-fixing line), or 'both' (a tangled line). The file has a CSV header.
  - `smartcommit.csv`: The decomposition results of SmartCommit in CSV format. Each line corresponds to a changed line and its associated group. The file has a CSV header.
  - `flexeme.csv`: The decomposition results of Flexeme in CSV format. Each line corresponds to a changed line and its associated group. The file has a CSV header.
  - `file_untangling.csv`: The decomposition results of file-based untangling in CSV format. Each line corresponds to a changed line and its associated group. The file has a CSV header.
  - `scores.csv`: The rand index score for each tool. The file has no CSV header. The columns are d4j_project,d4j_bug_id,smartcommit_score,flexeme_score,file_untangling_score
- `$UTB_OUTPUT/logs/`: Folder containing the logs of the `evalute.sh` script
- `$UTB_OUTPUT/repositories/`: Folder containing the checked out Defect4J bug repositories
- `$UTB_OUTPUT/metrics/`: Folder containing metrics for each Defects4J bug. See section [Metrics](#metrics) for more details.
- `decomposition_scores.csv`: Decomposition scores for each D4J bug evaluated. The file has no CSV header. The columns are d4j_project,d4j_bug_id,smartcommit_score,flexeme_score,file_untangling_score.
- `metrics.csv`: Aggregated metrics across all the D4J bugs evaluated. The file has no CSV header. The columns are d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated.

The detailed pipeline can be visualized in [diagrams/pipeline.drawio.svg](diagrams/pipeline.drawio.svg).

In addition to `data/d4j-5-bugs.csv`, there are 1 other pre-computed bug file that you can use: `data/d4j-compatible-bugs.csv` contains all the Defects4J bugs that are active and compatible with the experimental infrastructure. Bug projects marked as deprecated by Defects4J's authors are not included in this list of compatible bugs.
To generate a new bug file, see **Generating the bug file** section.

#### Optional steps
Run `./compute_metrics.sh data/d4j-5-bugs.csv $UTB_OUTPUT` to compute the metrics of the D4J bugs. See section [Metrics](#metrics) for more details.

The folder `analysis/` contains scripts to analyze the results of the evaluation. See `analysis/README.md` for more details.

#### Generating the bug file
To generate a bug file, run `src/bash/main/sample_bugs.sh data/d4j-compatible-bugs.csv <n>`, with `<n>`indicating the number of bugs to include.
Do not use `data/d4j-bugs-all.csv` as it contains bugs that are deprecated or not compatible with the experimental infrastructure (see **Limitations** section).

### Untangling one Defects4J bug
If you only want to evaluate the decomposition of one Defects4J bug, you can follow the pipeline presented in [diagrams/pipeline.drawio.svg](diagrams/pipeline.drawio.svg).

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
- `data/`: Contains list of Defects4J bugs to run the evaluation on
- `src/`: Experimental infrastructure scripts
  - `python/`: Python files
    - `main/`: Python source code for the evaluation
    - `test/`: Python tests
  - `bash/`: Bash files
    - `main/`: Bash source code for the evaluation
- `.env-template`: Template for the `.env` file containing computer-specific environment variables and paths
- `conftest.py`: Pytest configuration
- `evaluate.sh`: Script to run the evaluation on one Defects4J bug
- `evaluate_all.sh`: Script to run the evaluation for a list of Defects4J bugs
- `generate_all.sh` [WIP]: Script to only generate the ground truth for a list of Defects4J bugs
- `generate_ground_truth.sh` [WIP]: Script to generate different versions of the ground truth per Defects4J bug

## Ground truth

The ground truth is calculated from the original bug-fixing commit diff and the minimal bug inducing patch.

For visualization purpose, here is the [diagram](diagrams/diffs.drawio.svg) for ground truth construction.

See `ground_truth.py` for how the ground truth is calculated.

## Metrics

Commit metrics are calculated by `src/commit_metrics.py` and stored in `<out_dir>/metrics/`.
The supported metrics are:
  - Total number of files updated (i.e. both code and test files)
  - Number of test files updated 
  - Number of hunks 
  - Average hunk size 
  - Number of lines changed (i.e. all lines with +/- indicators in the original diff generated from pre-fix and post-fix versions).

## Manual analysis
This section explains how to manually analyse the decomposition results to qualitative assess the untangling tools compared to the ground truth.

1. Checkout D4J bug to analyse `defects4j checkout -p <project> -v <bug_id>b -w <repo_dir>`.
2. The diff for the bug is `git diff -U0 <buggy-commit> <fixed-commit>`. (obtained from Defects4J's `active-bugs.csv`
   file)
3. In another tab, open the ground truth `less $UTB_OUTPUT/evaluation/<project><bug_id>/truth.csv`
4. In another tab, open the Flexeme decomposition `less $UTB_OUTPUT/evaluation/<project><bug_id>/flexeme.csv`.
5. In another tab, open the SmartCommit decomposition `less $UTB_OUTPUT/evaluation/<project><bug_id>/truth.csv`.
6. Compare the decompositions with the ground truth, using the diff as reference for the changed content.
