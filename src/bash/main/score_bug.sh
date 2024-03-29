#!/bin/bash
# Translates SmartCommit results (JSON files) and Flexeme graphs
# (.dot files) in decomposition/D4J_bug for one D4J bug file to the
# line level. Each line is labelled with the group it belongs to and
# this is reported in a readable CSV file. Then, calculates the Rand
# Index for untangling results of 3 methods: SmartCommit, Flexeme, and
# File-based.
# Arguments:
# - $1: D4J Project name.
# - $2: D4J Bug Id.
# - $3: Directory where the results are stored.
# - $4: Directory where the repo is checked out.

# Results are outputted to evaluation/<D4J_bug> respective subfolder.
# Writes parsed untangling results to smartcommit.csv and flexeme.csv for each bug in /evaluation/<D4J_bug>
# Writes Rand Index scores computed to evaluation/<D4J_bug>/decomposition_scores.csv

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 4 ] ; then
    echo 'usage: score_bug.sh <project> <vid> <out_dir> <repository>'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

# Path containing the evaluation results
evaluation_dir="${out_dir}/evaluation/${project}_${vid}"
truth_csv="${evaluation_dir}/truth.csv"

echo ""
echo "Calculating Rand Index score for project $project, bug $vid, repository $repository"

# If the D4J bug does not exist, this means the tools have yet been run on the bug file's VC commit.
if [ ! -d "${repository}" ] ; then
  echo "Directory does not exist: ${repository}"
  echo "Exiting."
  exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/../../../check-environment.sh
set +o allexport

# Untangle with file-based approach
echo ""
file_untangling_out="${evaluation_dir}/file_untangling.csv"
if [ -f "$file_untangling_out" ]; then
  echo 'Untangling with file-based approach .................................. CACHED'
else
  echo -ne 'Untangling with file-based approach ..................................\r'
  if python3 src/python/main/filename_untangling.py "${truth_csv}" "${file_untangling_out}"
  then
      echo 'Untangling with file-based approach .................................. OK'
  else
      echo -ne 'Untangling with file-based approach .................................. FAIL\r'
      exit 1                # Return exit code 1 to mark this run as FAIl when called in score.sh
  fi
fi

# Compute untangling score
echo -ne 'Computing untangling scores ..........................................\r'
python3 src/python/main/untangling_score.py "$evaluation_dir" "${project}" "${vid}" > "${evaluation_dir}/scores.csv"
echo 'Computing untangling scores .......................................... OK'
