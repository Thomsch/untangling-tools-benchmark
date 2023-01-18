#!/bin/bash

# List the active bugs from defects4j in the format <project>,<vid>
defects4j pids | while read project ;
do
  defects4j bids -p $project | while read vid ;
  do
    echo "$project,$vid"
  done
done
