#!/bin/sh

# This script modifies a Java file in place to:
#  * remove comments
#  * remove blank lines
#  * remove trailing whitespace
#  * remove import statements

set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 MyJavaFile.java"
  exit 1
fi

file="$1"

cpp "$file" | grep -v '^#' | sed 's/[ \t]*$//' | grep -v '^$' | grep -v '^import' > "$file.cleaned"
mv -f "$file.cleaned" "$file"
