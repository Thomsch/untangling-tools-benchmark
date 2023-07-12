#!/bin/bash
# Translates SmartCommit results (JSON files) and Flexeme graphs ().dot files) in decomposition/D4J_bug for one D4J bug
# file to the line level. Each line is labelled with the group it belongs to and this is reported in
# a readable CSV file. Then, calculates the Rand Index for untangling results of 3 methods: SmartCommit, Flexeme, and File-based.
# - $1: D4J Project name
# - $2: D4J Bug Id
# - $3: Path where the results are stored.
# - $4: Path where the repo is checked out

# Results are outputted to evaluation/<D4J_bug> respective subfolder.
# Writes parsed decomposition results to smartcommit.csv and flexeme.csv for each bug in /evaluation/<D4J_bug>
# Writes Rand Index scores computed to /evaluation/<D4J_bug>/decomposition_scores.csv

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [$# -ne 4 ] ; then
    echo 'usage: score_bug.sh <project> <vid> <out_dir> <repository>'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

# Initialize related directory for input and output
evaluation_path="${out_dir}/evaluation/${project}_${vid}" # Path containing the evaluation results
truth_csv="${evaluation_path}/truth.csv"

echo -ne '\n'
echo "Calculating Rand Index score for project $project, bug $vid, repository $repository"

# Checkout Defects4J bug
mkdir -p "$repository"
defects4j checkout -p "$project" -v "$vid"b -w "$repository"

set -o allexport
# shellcheck source=/dev/null
. .env
set +o allexport

# Untangle with file-based approach
echo -ne '\n'
echo -ne 'Untangling with file-based approach .........................................\r'

file_untangling_out="${evaluation_path}/file_untangling.csv"

if [ -f "$file_untangling_out" ]; then
  echo -ne 'Untangling with file-based approach ..................................... CACHED\r'
else
  if python3 src/python/main/filename_untangling.py "${truth_csv}" "${file_untangling_out}"
  then
      echo -ne 'Untangling with file-based approach ....................................... OK\r'
  else
      echo -ne 'Untangling with file-based approach ..................................... FAIL\r'
  fi
fi
echo -ne '\n'

# Compute untangling score
echo -ne '\n'
echo -ne 'Computing untangling scores ...............................................\r'
python3 src/python/main/untangling_score.py "$evaluation_path" "${project}" "${vid}" > "${evaluation_path}/scores.csv"
echo -ne 'Computing untangling scores ............................................... OK'
echo -ne '\n'