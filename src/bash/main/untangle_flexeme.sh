#!/bin/bash
# Untangle and parse results from Flexeme tool.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 5 ] ; then
    echo 'usage: untangle_flexeme.sh <project repository> <commit id> <sourcepath> <classpath> <out file> '
    echo 'example: untangle_flexeme.sh path/to/Lang_1/ e3a4b0c src:test lib/* flexeme.csv'
    exit 1
fi


repository="$1" # The repository to run on
commit="$2" # Commit to untangle
sourcepath="$3" # Java source path for compilation
classpath="$4" # Java class path for compilation
output_file="$5" # Location of the file containing the decomposition

flexeme "$repository" "$commit" "$sourcepath" "$classpath" "$output_file"
