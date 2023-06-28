#!/bin/bash
# Generates the ground truth using the original fix and the minimized version of the D4J bug.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path to the checked out project repository
# - $4: The path where to output the ground truth results
#
# Writes the ground truth for the respective D4J bug file in evaluation/<project><id>/truth.csv
# - CSV header: {file, source, target, group}
#     - file: The relative file path from the project root for a change
#     - source: The line number of the change if the change is a deletion
#     - target: The line number of the change if the change is an addition
#     - group: 'fix' if the change is a fix, 'other' if the change is a non bug-fixing change
# Writes 3 unified diffs to the checked out bug to repo /<project><id>/diffs
# - vc.diff: Version Control diff
# - bug_fix.diff: bug-fixing diff
# - non_bug_fix.diff: Non bug-fixing diff
# Obtains 3 versions of the source code from Defects4J VCS History:

#set -o errexit    # Exit immediately if a command exits with a non-zero status
#set -o nounset    # Exit if script tries to use an uninitialized variable
#set -o pipefail   # Produce a failure status if any command in the pipeline fails

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

if [[ $# -ne 4 ]] ; then
    echo 'usage: ./ground_truth.sh <D4J Project> <D4J Bug id> <project repository> <truth file>'
    echo 'example: ./ground_truth.sh Lang 1 path/to/Lang_1/ evaluation_path/truth.csv'
    exit 1
fi

project=$1
vid=$2
repository=$3
truth_csv=$4
diff="diff"
workdir=$(pwd)

source ./scripts/d4j_utils.sh

# Parse the returned result into two variables
result=$(retrieve_revision_ids "$project" "$vid")
read -r revision_original revision_fixed <<< "$result"

# Obtain 3 Java files and clean before generating diff
inverted_patch="${DEFECTS4J_HOME}/framework/projects/${project}/patches/${vid}.src.patch"    # Retrieve the path to D4J bug-inducing minimized patch
target_file=$(grep -E "^\+\+\+ b/(.*)" "$inverted_patch" | sed -E "s/^\+\+\+ b\/(.*)/\1/")   # Retrieve target file name
source_file=$(grep -E "^\-\-\- a/(.*)" "$inverted_patch" | sed -E "s/^\-\-\- a\/(.*)/\1/")   # Retrieve source file name, V_buggy

# Obtain and filter comments, empty lines, whitespaces, and import statements ouf of 3 source code files: 
#       original.java (V_{n-1}), source_file (V_buggy), fixed.java (V_fixed)
cd $repository
mkdir "${diff}"
revision_buggy=$(git rev-parse HEAD)
git checkout "$revision_original"
cpp $source_file | python3 "${workdir}/src/clean_artifacts.py" "original.java"                                       # V_{n-1}
git checkout "$revision_buggy"
cpp $source_file | python3 "${workdir}/src/clean_artifacts.py" "buggy.java"                                          # V_buggy
git checkout "$revision_fixed"
cpp $source_file | python3 "${workdir}/src/clean_artifacts.py" "fixed.java"                                          # V_fixed
git checkout "$revision_buggy"                       
                                                                # Return to project repository
# Generate the three unified diff file, then clean the diff
cd -
diff -w -u "${repository}/buggy.java"  "${repository}/fixed.java" | python3 src/clean_artifacts.py "${repository}/${diff}/BF.diff"
diff -w -u "${repository}/original.java"  "${repository}/fixed.java" | python3 src/clean_artifacts.py "${repository}/${diff}/VC.diff"
patch --verbose -p1 --ignore-whitespace --output="${repository}/original_nobug_no_context.java" --fuzz 3 "${repository}/original.java" "${repository}/${diff}/BF.diff"
diff -w -U0 "${repository}/original_nobug_no_context.java"  "${repository}/fixed.java" >> "${repository}/${diff}/NBF.diff"

# Generate ground truth
d4j_diff "$project" "$vid" "$revision_original" "$revision_fixed" "$repository" | python3 src/ground_truth.py "$project" "$vid" "$truth_csv"
