#!/bin/bash

# Run from within a clone of a LLTC4J repository.
# Adds "cleaned" commits at the end of the repository.
# A "cleaned" commit contains only code-changes compared to the regular commit.
#
# The clone's HEAD should be on the last checkout in the repository (this is the
# case if you haven't run `git checkout` in that directory), and there should be
# no local modifications (this is the case if you have not edited or added any
# files).
#
# The clone's HEAD should be on the commit to untangle with no other commits
# afterwards. The repository should contain the following
# linear structure:
#
#   previous versions ---> V_{n-1} ---> V_n
#
# where V_{n-1} is the buggy version of the repository and V_n is the fixed version.
# (This diagram shows the code states; the commits are arrows in the diagram.)
#
# This script adds two new synthetic commits to the end of the history:
#
#    ... ---> V_n ---> C_{n-1} ---> C_n
#
# where "C" stands for "cleaned" or "code only".
#
# Each C_i is identical to V_i, except that C_i contains no comments
# or blank lines.  Thus, the differences between C_i and C_j are
# equivalent to the differences between V_i and V_j, except that the
# differences found in C* contain no comments, blank lines, or
# whitespace.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

# Retrieve the commit hash of the buggy and fixed commit.
revision_fixed=$(git rev-parse HEAD)
revision_buggy=$(git rev-parse HEAD~1)

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"

olddir="$(pwd)"
newdir="$olddir"_cleaned
tmpdir="/tmp/clean-lltc4j-repo-$(basename "$olddir")"

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
  "$SCRIPTDIR"/../clean-java-directory.sh
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

add_cleaned_commit "$revision_buggy" "Cleaned Buggy REVISION (= cleaned $revision_buggy)"
add_cleaned_commit "$revision_fixed" "Cleaned Fixed REVISION (= cleaned $revision_fixed)"

# Replace the unclean directory by the cleaned directory.
rm -rf "$olddir"
mv "$newdir" "$olddir"
echo "$(basename "$0"): success; result is in $olddir)"
cd "$olddir"
