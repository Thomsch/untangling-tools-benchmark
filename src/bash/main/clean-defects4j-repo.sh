#!/bin/bash

# Run from within a clone of a Defects4J repository.
# Adds "cleaned" commits at the end of the repository.
# A "cleaned" commit contains only code-changes compared to the regular commit.
# Example use:
#   defects4j checkout -p Lang -v 1b -w /tmp/lang_1_buggy
#   cd /tmp/lang_1_buggy
#   clean-defects4j-repo.sh
#   # Result is in /tmp/lang_1_buggy_cleaned
#
# The clone's HEAD should be on the last checkout in the repository (this is the
# case if you haven't run `git checkout` in that directory), and there should be
# no local modifications (this is the case if you have not edited or added any
# files).

# Currently, a Git repository checked out from Defects4J contains the following
# linear structure:
#
#   real commits from VCS ---> V_{n-1} ---> V_b ---> V_n
#
# where the last 3 commits are created by Defects4J.
# (This diagram shows the code states; the commits are arrows in the diagram.)
#
# This script adds three new synthetic commits to the end of the history:
#
#    ... ---> V_n ---> C_{n-1} ---> C_b ---> C_n
#
# where "C" stands for "cleaned" or "code only".
#
# Each C_i is identical to V_i, except that C_i contains no comments,
# blank lines, or import statements.  Thus, the differences between
# C_i and C_j are equivalent to the differences between V_i and V_j,
# except that the differences found in C* contain no comments, blank
# lines, or whitespace.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

# For debugging
# set -x

if [ $# -ne 2 ] ; then
    echo 'usage: clean-defects4j-repo.sh <D4J Project> <D4J Bug id>'
    echo 'example: clean-defects4j-repo.sh Lang 1'
    exit 1
fi

project="$1"
vid="$2"

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
set -o allexport
. "$SCRIPTDIR"/../../../check-environment.sh
set +o allexport

if [ ! -d .git ] ; then
  echo "$0: run at the top level of a git repository.  Exiting."
  exit 1
fi

num_changed_files="$(git status --porcelain | wc -l)"

if [ "$num_changed_files" -gt 0 ] ; then
  echo "$0: run in a git clone without local changes.  Exiting."
  exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPTDIR"/d4j_utils.sh

# Set two variables.
read -r v1 v2 <<< "$(print_revision_ids "$project" "$vid")"

v3="$(git rev-parse HEAD)"      # Buggy version

olddir="$(pwd)"
newdir="$olddir"_cleaned
tmpdir="/tmp/clean-defects4j-repo-$(basename "$olddir")"

# Reset $newdir to the current state of the repository, even if it already exists.
rm -rf "$newdir"
cp -Rp "$olddir" "$newdir"

# Adds a new commit to the git clone in $newdir.
add_cleaned_commit () {
  sha="$1"
  msg="$2"

  ## Using these two commands is a bit more paranoid.
  rm -rf "$tmpdir"
  cp -Rp "$newdir" "$tmpdir"

  cd "$tmpdir"
  git checkout -q "$sha"
  "$SCRIPTDIR"/clean-java-directory.sh
  rm -rf .git
  cp -rpf "$newdir/.git" "$tmpdir"

  cd "$newdir"
  # Delete all files.
  rm -rf -- ..?* .[!.]* *
  cp -af "$tmpdir/." "$newdir"
  git add .
  git commit -q -m "$msg"
  rm -rf "tmpdir/.git"
  cp -rpf .git "$tmpdir"
}

add_cleaned_commit "$v1" "Cleaned ORIGINAL_REVISION (= cleaned $v1)"
add_cleaned_commit "$v2" "Cleaned FIXED_VERSION (= cleaned $v2)"
add_cleaned_commit "$v3" "Cleaned BUGGY_VERSION (= cleaned $v3)"

# Replace the unclean directory by the cleaned directory.
rm -rf "$olddir"
mv "$newdir" "$olddir"
echo "$(basename "$0"): success; result is in ../$(basename "$olddir")"
cd "$olddir"
