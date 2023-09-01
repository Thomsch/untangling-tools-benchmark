#!/bin/sh

# This script processes every Java file in or under the current directory.
# It modifies the Java files in place to:
#  * remove comments
#  * remove blank lines
#  * remove trailing whitespace

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable

if [ $# -ne 0 ]; then
  echo "Do not pass arguments to $0"
  exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"

find . -name '*.java' -exec "$SCRIPTDIR"/clean-java-file.sh {} \;
