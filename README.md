# Untangling Tools Benchmark
Scripts to run the code changes benchmark.

## Requirements
- [Defects4J](https://github.com/rjust/defects4j) is installed and `defects4j` is on the PATH.
- Java 8 is installed and `java` is on the PATH.
- `python3` is installed and on the PATH.
- Flexeme is installed and on the PATH.
  1. Clone `https://github.com/Thomsch/Flexeme` locally.
  2. Install Flexeme from the clone `pip install -e path/to/flexeme/clone`.
  3. Install local dependencies `pip install -r requirements.txt`.

### Environment Variables
- `DEFECTS4J_HOME`: Location of the defect4j installation.
- `JAVA_SMARTCOMMIT`: Location of the java executable to run SmartCommit. Requires Java 11

## Untangling one D4J bug
Run `./evaluate.sh <project> <bug_id> <out_dir> <repo_dir>`. This will run the decomposition on the specified Defects4J <bug_id> in <project>. <out_dir> will contain the results of the decomposition. <repo_dir> is the directory used by Defects4J to checkout the specified project.

## Running the benchmark
1. Run `scripts/active_bugs.sh > all-commits.csv` (will generate from all project. Project `Chart` is not compatible
   with SmartCommit because it uses SVN)
    - Remove commits from `Chart` project from `all-commits.csv` because they are incompatible with SmartCommit. See **
      Limitations** sections.
2. Run `scripts/sample_bugs.sh all-commits.csv <n> > sampled_bugs.csv` with `<n>` indicating the number of bugs 
   to sample.
3. Run `./evaluate_all.sh sampled_bugs.csv`

### Aggregating decomposition elapsed time
All decomposition are timed. The result is stored in each decomposition folder.
To aggregated all of the results in one file, run `scripts/aggregate_time.sh`. 
It will create `out/time.csv` containing the runtime of each decomposition.

## Adding an untangling tool
Add a call to your untangling tool executable in `evaluate.sh`. Use the existing tools' code as a template.

## Limitations
- SmartCommit doesn't support SVN projects. For now, all commits in a SVN project are ignored by manually removing lines containing `Chart` in `out/commits.csv`.

## Improvements ideas
- Use Make to run the build pipeline.
    - The main benefit is that Make will take care of regenerating the correct files based on what is available / changed.
      - make: Use filename wildcard for each bug
      - rake has this options
