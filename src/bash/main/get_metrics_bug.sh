#!/bin/bash
# Computes 7 commit metrics for a Defects4J (D4J) bug.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path where the results are stored.
# - $4: Path where the repo is checked out
# Writes the results to a {<project> <id>}.csv file (with 1 row) in <out_dir>/metrics folder.
#    CSV header:
#    {d4j_project,d4j_bug_id,files_updated,test_files_updated,hunks,average_hunk_size,lines_updated, tangled_lines_count, tangled_hunks_count}

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
. .env
set +o allexport

if [ $# -ne 4 ] ; then
    echo 'usage: get_metrics_bug.sh <D4J Project> <D4J Bug id> <project repository> <out file>'
    echo 'example: get_metrics_bug.sh Lang 1 path/to/Lang_1/ metrics.csv'
    exit 1
fi

project="$1"
vid="$2"
out_dir="$3"
repository="$4"

# Initialize related directory for input and output
export metrics_dir="${out_dir}/metrics"
mkdir -p "$metrics_dir"

# Calculates the ground truth
echo -ne '\n'
echo "Calculating ground truth for project $project, bug $vid, repository $repository"

# Checkout Defects4J bug
mkdir -p "$repository"
defects4j checkout -p "$project" -v "$vid"b -w "$repository"

metrics_csv="${metrics_dir}/${project}_${vid}.csv" # Metrics for this bug

# Compute commit metrics
if [ -f "$metrics_csv" ]; then
    echo -ne 'Calculating metrics ..................................................... CACHED\r'
else
    . ./src/bash/main/d4j_utils.sh
    # Parse the returned result into two variables
    result="$(retrieve_revision_ids "$project" "$vid")"
    read -r revision_buggy revision_fixed <<< "$result"
    if d4j_diff "$project" "$vid" "$revision_buggy" "$revision_fixed" "$workdir" | python3 src/python/main/commit_metrics.py "${project}" "${vid}" > "$metrics_csv"
    then
        echo -ne 'Calculating metrics ..................................................... OK\r'
    else
        echo -ne 'Calculating metrics ..................................................... FAIL\r'
    fi
fi
echo -ne '\n'