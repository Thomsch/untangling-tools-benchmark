#!/bin/bash
# Cleans this repository and Flexeme's for the double-blind paper submission.
# Before running this script, create "$out_dir", and move untangling result and the analysis results into it.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 1 ] ; then
    echo 'usage: clean_repositories.sh <out_dir>'
    exit 1
fi

export out_dir="$1" # The directory where to put cleaned repositories (e.g., 'artifacts')
mkdir -p "$out_dir"

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"

# Clone repositories
echo "Cloning repositories into $out_dir"
export GIT_TERMINAL_PROMPT=0
git -C "$out_dir" clone --depth 1 https://github.com/Thomsch/untangling-tools-benchmark \
  || git -C "$out_dir" clone --depth 1 git@github.com:Thomsch/untangling-tools-benchmark.git
git -C "$out_dir" clone --depth 1 https://github.com/Thomsch/flexeme \
  || git -C "$out_dir" clone --depth 1 git@github.com:Thomsch/Flexeme.git
echo "Cloning repositories into $out_dir: DONE"

echo "Cleaning all files in $out_dir"

clean_repo() {
    repo_dir="$1"
    rm -rf "$repo_dir/.git"
    rm -rf "$repo_dir/.github"
    rm -rf "$repo_dir/.vscode"
    find "$out_dir" -name '.DS_Store' -type f -delete
    find "$out_dir" -type f -print0 | xargs -0 sed -i -f clean_repositories.sed
}

clean_repo "$out_dir/untangling-tools-benchmark"
clean_repo "$out_dir/flexeme"

echo "Cleaning all files in $out_dir: DONE"

# Move double-blind/README.md to $OUT_DIR
cp "$SCRIPTDIR"/README.md "$out_dir"

# Remove cleaning script and README.MD from the cleaned repository
rm -rf "$out_dir/untangling-tools-benchmark/double-blind"
