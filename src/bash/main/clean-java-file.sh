#!/bin/bash

# This script modifies a Java file in place to:
#  * remove comments
#  * remove blank lines
#  * remove trailing whitespace

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 1 ]; then
  echo "Usage: $0 MyJavaFile.java"
  exit 1
fi

file="$1"

# Remove in-line, block comments, trailing whitespaces, and blank lines
if [ "$(uname)" = "Darwin" ]; then
  alias pre_processor='clang -x c++ -E'
elif [ "$(uname)" = "Linux" ]; then
  alias pre_processor='cpp -fpreprocessed -dD -E'
else
  echo "Unsupported operating system."
  exit 1
fi

pre_processor "$file" | grep -v '^#' | sed 's/[ \t]*$//' | grep -v '^$' | grep -v '^\s*//' > "$file.cleaned"

mv -f "$file.cleaned" "$file"
