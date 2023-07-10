#!/bin/bash
# List the active bugs from defects4j in the format <project>,<vid>

set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

defects4j pids | while read -r project ;
do
  defects4j bids -p "$project" -A | while read -r vid ; # -A gets active and deprecated bugs.
  do
    echo "$project,$vid"
  done
done
