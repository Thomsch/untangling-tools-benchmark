#!/bin/sh

# This script modifies a Java file in place to:
#  * remove comments
#  * remove blank lines
#  * remove trailing whitespace

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable

if [ $# -ne 1 ]; then
  echo "Usage: $0 MyJavaFile.java"
  exit 1
fi

file="$1"

cpp -fpreprocessed -dD -E "$file" | grep -v '^#' | sed 's/[ \t]*$//' | grep -v '^$' | grep -v '^\s*//' > "$file.cleaned"  # Remove in-line, block comments, trailing whitespaces, and blank lines
mv -f "$file.cleaned" "$file"
