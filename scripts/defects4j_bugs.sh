#!/bin/bash

# List the active bugs from defects4j in the format <project>,<vid>
defects4j pids | while read -r project ;
do
  defects4j bids -p "$project" -A | while read -r vid ; # -A gets active and deprecated bugs.
  do
    echo "$project,$vid"
  done
done
