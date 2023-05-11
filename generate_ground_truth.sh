#!/bin/bash
# Generate the ground truth for a Defects4J bug.
# Two ground truths are generated:
# 1. Include all the original changes in the bug fix.
# 2. Include only the source codes changes that are not comments, import, or test changes.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 4 ]] ; then
    echo 'usage: evaluate.sh <D4J Project> <D4J Bug id> <out_dir> <repo_root>'
    echo 'example: evaluate.sh Lang 1 out/ repositories/'
    exit 1
fi

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

if [[ -z "${JAVA_11}" ]]; then
  echo 'JAVA_11 environment variable not set.'
  echo 'Please set it to the path of a Java 11 JDK.'
  exit 1
fi

project=$1
vid=$2
out_path=$3 # Path where the results are stored.
repo_root=$4 # Path where the repo is checked out
workdir="${repo_root}/${project}_${vid}"

evaluation_path="${out_path}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground
# truth, decompositions in CSV format.

mkdir -p "${evaluation_path}"

# Check that Java is 1.8 for Defects4j.
# Defects4J will use whatever is on JAVA_HOME.
version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)
if [[ $(echo "$version != 1.8" | bc) == 1 ]] ; then
    echo "Unsupported Java Version: ${version}. Please use Java 8."
    exit 1
fi

echo "Generating ground truth for $project, bug $vid, repository $workdir"

# Checkout Defects4J bug
mkdir -p "$workdir"
defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

# Get commit hash
commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)

truth_all_out="${evaluation_path}/truth_all.csv"
truth_code_out="${evaluation_path}/truth_code.csv"

#
# Calculates the ground truth
#
echo -ne '\n'
echo -ne 'Calculating ground truth ..................................................\r'


./scripts/ground_truth.sh "$project" "$vid" "$workdir" "$truth_all_out" "$commit" "False"
code=$?
if [ $code -eq 0 ]
then
    echo -ne 'Calculating ground truth (all) .................................................. OK\r'
else
    echo -ne 'Calculating ground truth (all) .................................................. FAIL\r'
fi
echo -ne '\n'

./scripts/ground_truth.sh "$project" "$vid" "$workdir" "$truth_code_out" "$commit" "True"
code=$?
if [ $code -eq 0 ]
then
    echo -ne 'Calculating ground truth (code) .................................................. OK\r'
else
    echo -ne 'Calculating ground truth (code) .................................................. FAIL\r'
fi
echo -ne '\n'
