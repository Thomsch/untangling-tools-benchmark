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

cpp -fpreprocessed -dD -E "$file" | grep -v '^#' | sed 's/[ \t]*$//' | grep -v '^$' | grep -v '^\s*//' > "$file.cleaned"  # Remove in-line, block comments, trailing whitespaces, and blank lines
mv -f "$file.cleaned" "$file"