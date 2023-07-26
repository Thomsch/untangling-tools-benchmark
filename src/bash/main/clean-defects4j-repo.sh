#!/bin/sh

# Add "cleaned" commits at the end of a repository cloned from Defects4J.
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
# Each C_i is exactly like V_i, except that C_i contains no comments, blank
# lines, or import statements.
# Thus, the diffs between C_i and C_j are exactly like the diffs between V_i and
# V_j, except that the C* diffs contain no comments, blank lines, or whitespace.

set -e

# For debugging
# set -x

if [ ! -d .git ] ; then
  echo "$0: run at the top level of a git repository"
  exit 1
fi

changed_files="$(git status --porcelain | wc -l)"
if [ "$changed_files" -gt 0 ] ; then
  echo "$0: run in a git clone without local changes"
  exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"


v1="$(git rev-parse HEAD~2)"
v2="$(git rev-parse HEAD~1)"
v3="$(git rev-parse HEAD)"

olddir="$(pwd)"
newdir="$olddir"_cleaned
tmpdir="/tmp/clean-defects4j-repo-$(basename "$olddir")"

rm -rf "$newdir"
cp -Rp "$olddir" "$newdir"
rm -rf "$tmpdir"
cp -Rp "$olddir" "$tmpdir"

add_cleaned_commit () {
  sha="$1"
  msg="$2"

  cd "$tmpdir"
  git checkout -q "$sha"
  "$SCRIPTDIR"/clean-java-directory.sh
  rm -rf .git
  # Remove everything but the .git directory in $newdir
  (cd "$newdir" && find . -path ./.git -prune -o -name "." -prune -o -exec rm -rf {} +)
  cp -af "$tmpdir/." "$newdir"
  cd "$newdir"
  git commit -q -am "$msg"
  cp -rpf .git "$tmpdir"
}

add_cleaned_commit "$v1" "Cleaned POST_FIX_REVISION"
add_cleaned_commit "$v2" "Cleaned FIXED_VERSION"
add_cleaned_commit "$v3" "Cleaned BUGGY_VERSION"

echo "$(basename "$0"): success; result is in ../$(basename "$newdir")"
