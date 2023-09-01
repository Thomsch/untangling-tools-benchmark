#!/bin/bash

# This script takes a Defects4J project id, a bug id, and a project repository
# as input and outputs all the changed lines for the D4J bug. The changed lines
# are not filtered unlike in ground_truth.sh.
#
# The result is outputed to stdout in a CSV format with the following columns:
#   - file path (string): the path of the file where the change occurred.
#   - source: the line number of the line that was deleted or changed in the buggy version.
#   - target: the line number of the line that was added or changed in the fixed version.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 3 ]] ; then
    echo 'usage: changed_lines.sh <D4J Project> <D4J Bug id> <project repository>'
    echo 'example: changed_lines.sh Lang 1 path/to/Lang_1/'
    exit 1
fi

PROJECT=$1
VID=$2
REPO="$3"

source ./src/bash/main/d4j_utils.sh

# Set two variables.
read -r revision_buggy revision_fixed <<< "$(retrieve_revision_ids "$PROJECT" "$VID")"

d4j_diff "$PROJECT" "$VID" "$revision_buggy" "$revision_fixed" "$REPO" | python3 src/python/main/parse_patch.py
