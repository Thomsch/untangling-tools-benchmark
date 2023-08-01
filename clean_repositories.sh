#!/bin/bash
# Cleans this repository and Flexeme's for the double-blind paper submission.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 1 ] ; then
    echo 'usage: clean_repositories.sh <out_dir>'
    exit 1
fi


export out_dir="$1" # The directory where to put cleaned repositories


mkdir -p "$out_dir"

# Clone repositories
# git clone --depth 1 https://github.com/Thomsch/untangling-tools-benchmark "$out_dir/untangling-tools-benchmark"
# git clone --depth 1 https://github.com/Thomsch/flexeme "$out_dir/flexeme"

# Delete .git .github .vscode folders in both repositories
clean_repo() {
    repo_dir="$1"
    rm -rf "$repo_dir/.git"
    rm -rf "$repo_dir/.github"
    rm -rf "$repo_dir/.vscode"
    
}

clean_repo "$out_dir/untangling-tools-benchmark"
clean_repo "$out_dir/flexeme"
