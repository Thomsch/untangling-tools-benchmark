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

# Remove comments, line number directives left by cpp, trailing whitespace, and blank lines
cpp -fpreprocessed -dD -E "$file" | grep -v '^#' | sed 's/[ \t]*$//' | grep -v '^$' > "$file.cleaned"
mv -f "$file.cleaned" "$file"
