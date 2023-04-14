# Untangling Tools Benchmark

Benchmark for comparing untangling tools on real bug-fixing commits.

## Requirements

- Python 3.8 is installed and on the PATH.
- Java 8 is installed and on the PATH.
- Java 11 is installed, but is not on the PATH.

## Installation

1. Clone this repository locally `git clone https://github.com/Thomsch/untangling-tools-benchmark`.
2. Go into the repository folder `cd untangling-tools-benchmark`.
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
8. Copy `.env-template` to `.env` and fill in the environment variables `cp .env-template .env`.
   - `DEFECTS4J_HOME`: Location of the Defects4J installation (e.g., `~/defects4j`)
   - `JAVA_SMARTCOMMIT`: Location of the **Java 11** executable to run SmartCommit. Requires Java 11.

## Running the benchmark
1. Run `scripts/defects4j_bugs.sh > d4j-bugs.csv` (will generate from all project. Project `Chart` is not 
   compatible
   with SmartCommit because it uses SVN)
    - Remove commits from `Chart` project from `d4j-bugs.csv` because they are incompatible with SmartCommit.
      See **Limitations** sections.
2. Run `./evaluate_all.sh d4j-bugs.csv <out_dir>`.
    - This will run the decomposition on all bugs in `d4j-bugs.csv`.
    - `<out_dir>` will contain the results of the decomposition.
    - If you want to only run on a few bugs, use `scripts/sample_bugs.sh d4j-bugs.csv <n>`, with `<n>` 
      indicating the number of bugs to sample.

## Untangling one D4J bug
1. Run `./evaluate.sh <project> <bug_id> <out_dir> <repo_dir>`. 
   - This will run the decomposition on the specified Defects4J `<bug_id>` in `<project>`. 
   - `<out_dir>` will contain the results of the decomposition. 
   - `<repo_dir>` is the directory used by Defects4J to checkout the specified project.

### Aggregating decomposition elapsed time
All decomposition are timed. The result is stored in each decomposition folder.
To aggregated all of the results in one file, run `scripts/aggregate_time.sh`. 
It will create `out/time.csv` containing the runtime of each decomposition.

## Adding an untangling tool
Add a call to your untangling tool executable in `evaluate.sh`. Use the existing tools' code as a template.

## Statistics
Run `scripts/lines_count.sh` to get the number of changed lines in each D4J bug.

## Limitations
- SmartCommit doesn't support SVN projects. For now, all commits in a SVN project are ignored by manually removing lines containing `Chart` in `out/commits.csv`.

## Improvements ideas
- Use Make to run the build pipeline.
    - The main benefit is that Make will take care of regenerating the correct files based on what is available / changed.
      - make: Use filename wildcard for each bug
      - rake has this options
