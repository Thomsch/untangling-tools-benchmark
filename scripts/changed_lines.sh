#!/bin/bash

project=$1
vid=$2

REPO="$3/.git"
COMMIT="$4"

source ./scripts/diff_util.sh

# Git diff -U0 on top of Vn +  Pipe output to changed_lines.py
diff "$project" "$vid" "$COMMIT" | python3 src/parse_patch.py
# git --git-dir="$REPO" diff -U0 "$COMMIT"^ "$COMMIT" | python3 src/parse_patch.py
