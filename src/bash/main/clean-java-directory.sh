#!/bin/sh

# This script processes every Java file in or under the current directory.
# It modifies the Java files in place to:
#  * remove comments
#  * remove blank lines
#  * remove trailing whitespace
#  * remove import statements

set -e

if [ $# -ne 0 ]; then
  echo "Do not pass arguments to $0"
  exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"

find . -name '*.java' -exec "$SCRIPTDIR"/clean-java-file.sh {} \;
