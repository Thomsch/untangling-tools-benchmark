#!/bin/bash
# Generates 3 diffs and 3 source code versions, for a Defects4J bug.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path to the checked out project repository

# Writes 3 unified diffs to the checked out bug to repo /<project><id>/diffs and 3 source code artifacts to the project repository
# - VC.diff: Version Control diff
# - BF.diff: Bug-fixing diff
# - NBF.diff: Non bug-fixing diff
# - original.java: The buggy source code in version control
# - buggy.java: The buggy source code after all non-bug fixes are applied
# - fixed.java: The fixed source code in version control

set -o allexport
# shellcheck source=/dev/null
. .env
set +o allexport

if [ $# -ne 3 ] ; then
    echo 'usage: generate_artifacts.sh <D4J Project> <D4J Bug id> <project repository>'
    echo 'example: generate_artifacts.sh Lang 1 path/to/Lang_1/'
    exit 1
fi

project="$1"
vid="$2"
repository="$3"

# Generate 6 artifacts
echo -ne '\n'
echo "Generating diff and code artifacts for project $project, bug $vid, repository $repository"

# Initialize related directories for input and output
workdir="$(pwd)"
diff_dir="${repository}/diff"

# Checkout Defects4J bug
mkdir -p "$repository"
defects4j checkout -p "$project" -v "$vid"b -w "$repository"

# Generate six artifacts (three unified diffs, three source code files)
bug_fix_diff_out="${diff_dir}/BF.diff"

if [ -f "$bug_fix_diff_out" ]; then
    echo -ne 'Generating diff and code artifacts ................................................ CACHED\r'
else
    . ./src/bash/main/d4j_utils.sh

    # Parse the returned revision_ids into two variables
    read -r revision_original revision_fixed <<< "$(retrieve_revision_ids "$project" "$vid")"

    cd "$repository" || exit 1
    mkdir -p "$diff_dir"
    revision_buggy=$(git rev-parse HEAD)

    # D4J bug-inducing minimized patch
    inverted_patch="${DEFECTS4J_HOME}/framework/projects/${project}/patches/${vid}.src.patch"
    if [ ! -f "${inverted_patch}" ] ; then
        echo "Bad project or bug id; file does not exist: ${inverted_patch}"
        exit 1
    fi

    source_file=$(grep -E "^\-\-\- a/(.*)" "$inverted_patch"  \
    | sed -E "s/^\-\-\- a\/(.*)/\1/")   # Retrieve source file containing the bug

    cd - || exit 1

    # Generate the VC diff but not clean yet, to generate commit metrics first
    d4j_diff "$project" "$vid" "$revision_original" "$revision_fixed" "$repository" >> "${diff_dir}/VC.diff" 
    # Generate the 3 diff files with no context lines, then clean the diffs.
    d4j_diff "$project" "$vid" "$revision_original" "$revision_fixed" "$repository" \
        | python3 "${workdir}/src/python/main/clean_artifacts.py" "${diff_dir}/VC_clean.diff"
    d4j_diff "$project" "$vid" "$revision_original"  "$revision_buggy" "$repository" \
        | python3 "${workdir}/src/python/main/clean_artifacts.py" "${diff_dir}/NBF.diff"
    d4j_diff "$project" "$vid" "$revision_buggy"  "$revision_fixed" "$repository" \
        | python3 "${workdir}/src/python/main/clean_artifacts.py" "${diff_dir}/BF.diff"

    # Remove comments, empty lines, whitespaces, and import statements from 3 source code files:
    #       original.java (V_{n-1}), source_file (V_buggy), fixed.java (V_fixed)
    # TODO: This doesn't handle when source file contain multiple filenames
    cd "$repository" || exit 1
    git checkout "$revision_original"
    cpp "$source_file" | python3 "${workdir}/src/python/main/clean_artifacts.py" "original.java"                                       # V_{n-1}
    git checkout "$revision_buggy"
    cpp "$source_file" | python3 "${workdir}/src/python/main/clean_artifacts.py" "buggy.java"                                          # V_buggy
    git checkout "$revision_fixed"
    cpp "$source_file" | python3 "${workdir}/src/python/main/clean_artifacts.py" "fixed.java"                                          # V_fixed
    git checkout "$revision_buggy"                                                                                       # Return to project repository

    cd - || exit 1                                                                                    # Return to project repository
    code=$?
    if [ $code -eq 0 ]
    then
        echo -ne 'Generating diff and code artifacts .................................................. OK\r'
    else
        echo -ne 'Generating diff and code artifacts .................................................. FAIL\r'
    fi
fi
echo -ne '\n'