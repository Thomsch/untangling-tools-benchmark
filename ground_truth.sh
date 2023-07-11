#!/bin/bash
# Generates the ground truth using the original fix and the minimized version for a list of Defects4J (D4J) bugs.
# - $1: Path to the file containing the bugs to untangle and evaluate.
# - $2: Path to the directory where the results are stored and repositories checked out.

# Writes the ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
# - CSV header: {file, source, target, group}
#     - file: The relative file path from the project root for a change
#     - source: The line number of the change if the change is a deletion
#     - target: The line number of the change if the change is an addition
#     - group: 'fix' if the change is a fix, 'other' if the change is a non bug-fixing change

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 2 ]] ; then
    echo 'usage: evaluate_all.sh <bugs_file> <out_dir>'
    exit 1
fi

# Check that Java is 1.8 for Defects4j.
# Defects4J will use whatever is on JAVA_HOME.
version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)
if [[ $(echo "$version != 1.8" | bc) == 1 ]] ; then
    echo "Unsupported Java Version: ${version}. Please use Java 8."
    exit 1
fi

source ./src/bash/main/d4j_utils.sh

export bugs_file=$1 # Path to the file containing the bugs to untangle and evaluate.
export out_dir=$2 # Path to the directory where the results are stored and repositories checked out.
export workdir="${out_dir}/repositories"
export metrics_dir="${out_dir}/metrics"
export evaluation_dir="${out_dir}/evaluation"

evaluation_path="${out_dir}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground
# truth, decompositions in CSV format.
metrics_path="${out_dir}/metrics" # Path containing the commit metrics.

mkdir -p "$workdir"
mkdir -p "$metrics_dir"
mkdir -p "$evaluation_dir"

get_truth_bug() {
  evaluation_path="${out_path}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground
  # truth, decompositions in CSV format.
  metrics_path="${out_path}/metrics" # Path containing the commit metrics.
  mkdir -p "${evaluation_path}"
  mkdir -p "${metrics_path}"

  # Compute commit metrics
  metrics_csv="${metrics_path}/${project}_${vid}.csv" # Metrics for this bug
  if [[ -f "$metrics_csv" ]]; then
    echo -ne 'Calculating metrics ..................................................... CACHED\r'
  else
    source ./src/bash/main/d4j_utils.sh

    # Parse the returned result into two variables
    result=$(retrieve_revision_ids "$project" "$vid")
    read -r revision_buggy revision_fixed <<< "$result"

    d4j_diff "$project" "$vid" "$revision_buggy" "$revision_fixed" "$workdir" | python3 src/python/main/commit_metrics.py "${project}" "${vid}" > "$metrics_csv"
    code=$?
    if [ $code -eq 0 ]
    then
        echo -ne 'Calculating metrics ..................................................... OK\r'
    else
        echo -ne 'Calculating metrics ..................................................... FAIL\r'
    fi
  fi

  # Calculates the ground truth
  echo -ne '\n'
  echo "Constructing ground truth for project $project, bug $vid"
  echo -ne 'Calculating ground truth ..................................................\r'

  truth_csv="${evaluation_path}/truth.csv"

  if [[ -f "$truth_csv" ]]; then
    echo -ne 'Calculating ground truth ................................................ CACHED\r'
  else
    d4j_diff "$project" "$vid" "$revision_buggy" "$revision_fixed" "$repository" | python3 src/python/main/ground_truth.py "$project" "$vid" "$truth_csv"
    code=$?
    if [ $code -eq 0 ]
    then
        echo -ne 'Calculating ground truth .................................................. OK\r'
    else
        echo -ne 'Calculating ground truth .................................................. FAIL\r'
    fi
  fi
  echo -ne '\n'
}

export -f get_truth_bug
parallel --colsep "," get_truth_bug {} < "$bugs_file"