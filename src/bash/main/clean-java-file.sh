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

pre_process() {
  file="$1"

  if [ "$(uname)" = "Darwin" ]; then
    clang -x c++ -E "$file"
  elif [ "$(uname)" = "Linux" ]; then
    cpp -fpreprocessed -dD -E "$file"
  else
    echo "Unsupported operating system."
    exit 1
  fi
}

# Remove in-line, block comments, trailing whitespaces, and blank lines
pre_process "$file" | grep -v '^#' | sed 's/[[:space:]]*$//' | grep -v '^$' | grep -v '^\s*//' > "$file.cleaned"

mv -f "$file.cleaned" "$file"
