#!/bin/bash
# Computes 7 commit metrics for a Defects4J (D4J) bug.
# Arguments:
# - $1: D4J Project name.
# - $2: D4J Bug id.
# - $3: Directory where the results are stored.
# - $4: Directory where the repo is checked out.
# Writes the results to a {<project>_<id>}.csv file (with 1 row) in <out_dir>/metrics folder.

#    CSV header:
#    {d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated,tangled_lines_count,tangled_hunks_count}

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
if [ -z "$DEFECTS4J_HOME" ] || [ -z "$JAVA11_HOME" ] ; then
  . .env
fi
set +o allexport

if [ $# -ne 4 ] ; then
    echo 'usage: get_metrics_bug.sh <D4J Project> <D4J Bug id> <out file> <project clone>'
    echo 'example: get_metrics_bug.sh Lang 1 path/to/Lang_1/'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

export metrics_dir="${out_dir}/metrics"
mkdir -p "$metrics_dir"

# Calculates the diff metrics
echo -ne '\n'
echo "Calculating diff metrics for project $project, bug $vid, repository $repository"

# If D4J bug repository does not exist, checkout the D4J bug to repository and
# generates 6 artifacts for it.
if [ ! -d "${repository}" ] ; then
  mkdir -p "$repository"
  ./src/bash/main/generate_artifacts_bug.sh "$project" "$vid" "$repository"
fi

# Metrics for this bug.  This file is the output of this script.
metrics_csv="${metrics_dir}/${project}_${vid}.csv"

# Compute commit metrics
if [ -f "$metrics_csv" ]; then
    echo 'Calculating metrics ..................................................... CACHED'
else
    if python3 src/python/main/diff_metrics.py "${project}" "${vid}" "${repository}" > "$metrics_csv"
    then
        echo 'Calculating metrics ..................................................... OK'
    else
        echo -ne 'Calculating metrics ..................................................... FAIL\r'
        exit 1        # Return exit code 1 to mark this run as FAIl when called in compute_metrics.sh
    fi
fi
