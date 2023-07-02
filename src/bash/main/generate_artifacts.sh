#!/bin/bash
# Generates the three diff artifacts based on the minimized bug-inducing patch in Defects4J.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path to the checked out project repository

# Writes 3 unified diffs to the checked out bug to repo /<project><id>/diffs and 3 source code artifacts to the project repository
# - vc.diff: Version Control diff
# - bug_fix.diff: bug-fixing diff
# - non_bug_fix.diff: Non bug-fixing diff
# - original.java: The buggy source code in version control
# - buggy.java: The buggy source code after all non-bug fixes are applied
# - fixed.java: The fixed source code after all minimal bug fixes are applied

set -o allexport
source .env
set +o allexport

if [[ $# -ne 3 ]] ; then
    echo 'usage: ./generate_artifacts.sh <D4J Project> <D4J Bug id> <project repository>'
    echo 'example: ./generate_artifacts.sh Lang 1 path/to/Lang_1/'
    exit 1
fi

project=$1
vid=$2
repository=$3
diff="diff"
workdir=$(pwd)

source ./src/bash/main/d4j_utils.sh

# Parse the returned result into two variables
result=$(retrieve_revision_ids "$project" "$vid")
read -r revision_original revision_fixed <<< "$result"

# Obtain the 3 source code files (V_{n-1}), (V_buggy), (V_fixed)
cd "$repository" || exit 1
mkdir "${diff}"
revision_buggy=$(git rev-parse HEAD)

# Obtain 3 Java files and clean before generating diff
inverted_patch="${DEFECTS4J_HOME}/framework/projects/${project}/patches/${vid}.src.patch"    # Retrieve the path to D4J bug-inducing minimized patch
# target_file=$(grep -E "^\+\+\+ b/(.*)" "$inverted_patch" | sed -E "s/^\+\+\+ b\/(.*)/\1/")   # Retrieve target file name
source_file=$(grep -E "^\-\-\- a/(.*)" "$inverted_patch" | sed -E "s/^\-\-\- a\/(.*)/\1/")   # Retrieve source file name, V_buggy

# Obtain and filter comments, empty lines, whitespaces, and import statements ouf of 3 source code files: 
#       original.java (V_{n-1}), source_file (V_buggy), fixed.java (V_fixed)

git checkout "$revision_original"
cpp "$source_file" | python3 "${workdir}/src/python/main/clean_artifacts.py" "original.java"                                       # V_{n-1}
git checkout "$revision_buggy"
cpp "$source_file" | python3 "${workdir}/src/python/main/clean_artifacts.py" "buggy.java"                                          # V_buggy
git checkout "$revision_fixed"
cpp "$source_file" | python3 "${workdir}/src/python/main/clean_artifacts.py" "fixed.java"                                          # V_fixed
git checkout "$revision_buggy"                                                                                       # Return to project repository

# Generate the three unified diff file with no context lines, then clean the diff
cd - || exit 1
diff -w -U0 "${repository}/buggy.java"  "${repository}/fixed.java" | python3 src/python/main/clean_artifacts.py "${repository}/${diff}/bug_fix.diff"
diff -w -U0 "${repository}/original.java"  "${repository}/fixed.java" | python3 src/python/main/clean_artifacts.py "${repository}/${diff}/VC.diff"
diff -w -U0 "${repository}/original.java"  "${repository}/buggy.java" | python3 src/python/main/clean_artifacts.py "${repository}/${diff}/non_bug_fix.diff"
patch --verbose -p1 --ignore-whitespace --output="${repository}/original_nobug_no_context.java" --fuzz 3 "${repository}/original.java" "${repository}/${diff}/bug_fix.diff"
diff -w -U0 "${repository}/original_nobug_no_context.java"  "${repository}/fixed.java" >> "${repository}/${diff}/NBF.diff"

# For debugging 
# code=$?
# echo "exit code=${code}"