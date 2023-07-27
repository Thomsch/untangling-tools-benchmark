#!/bin/sh

# This script modifies a Java file in place to:
#  * remove comments
#  * remove blank lines
#  * remove trailing whitespace

set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 MyJavaFile.java"
  exit 1
fi

file="$1"

# The `sed` command uses a literal tab character instead of '\t'
# because MacOSX does not understand the \t character.
cpp "$file" | grep -v '^#' | sed 's/[   ]*$//' | grep -v '^$' > "$file.cleaned"
mv -f "$file.cleaned" "$file"