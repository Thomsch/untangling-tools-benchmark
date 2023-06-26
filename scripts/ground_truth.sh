#!/bin/bash
# Generates the ground truth using the original fix and the minimized version of the D4J bug.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path to the checked out project repository
# - $4: The path where to output the ground truth results
# - $5: The path to output the 3 diff artifacts
#
# Writes the ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
# - CSV header: {file, source, target, group}
#     - file: The relative file path from the project root for a change
#     - source: The line number of the change if the change is a deletion
#     - target: The line number of the change if the change is an addition
#     - group: 'fix' if the change is a fix, 'other' if the change is a non bug-fixing change
# Writes 3 unified diffs to the checked out bug repo /<project><id>/diffs
# - vc.diff: Version Control diff
# - bug_fix.diff: bug-fixing diff
# - non_bug_fix.diff: Non bug-fixing diff

#set -o errexit    # Exit immediately if a command exits with a non-zero status
#set -o nounset    # Exit if script tries to use an uninitialized variable
#set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

if [[ $# -ne 5 ]] ; then
    echo 'usage: ./ground_truth.sh <D4J Project> <D4J Bug id> <project repository> <truth file> <diff folder>'
    echo 'example: ./ground_truth.sh Lang 1 path/to/Lang_1/ evaluation_path/truth.csv diff'
    exit 1
fi

project=$1
vid=$2
repository=$3
truth_out=$4
diff=$5

source ./scripts/d4j_utils.sh

# Parse the returned result into two variables
result=$(retrieve_revision_ids "$project" "$vid")
read -r revision_buggy revision_fixed <<< "$result"

# Generate the three unified diff file
inverted_patch="${DEFECTS4J_HOME}/framework/projects/${project}/patches/${vid}.src.patch"    # Retrieve the path to D4J bug-inducing minimized patch
target_file=$(grep -E "^\+\+\+ b/(.*)" "$inverted_patch" | sed -E "s/^\+\+\+ b\/(.*)/\1/")   # Retrieve target file name
source_file=$(grep -E "^\-\-\- a/(.*)" "$inverted_patch" | sed -E "s/^\-\-\- a\/(.*)/\1/")   # Retrieve source file name

# Obtain 3 Java files and clean before generating diff
cd $repository
mkdir "${diff}"
git diff --ignore-all-space -U0 "$revision_buggy"  "$source_file" >> "${diff}/non_bug_fix.diff"       # Retrieve non bug fixing diff
patch --input="$inverted_patch" -p1 -R < "$inverted_patch"                                               # Apply Reverse patch to buggy source file to obtain fixed code
git diff --ignore-all-space -U0 >> "${diff}/bug_fix.diff"
git diff --ignore-all-space -U0 "$revision_buggy"  "$source_file" >> "${diff}/VC.diff"

patch --input="$inverted_patch" -p1 < "$inverted_patch"                                         # Reverse the patch to ensure the D4J repo stays intact

cd -
# Generate ground truth
d4j_diff "$project" "$vid" "$revision_buggy" "$revision_fixed" "$repository" | python3 src/ground_truth.py "$project" "$vid" "$truth_out"