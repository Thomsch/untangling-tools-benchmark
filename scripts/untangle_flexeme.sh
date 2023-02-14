#!/bin/bash

# Untangle and parse results from Flexeme tool.

repository=$1 # Path to the repository to run on
commit=$2 # Commit to untangle
sourcepath=$3 # Java source path for compilation
classpath=$4 # Java class path for compilation
output_file=$5 # Location of the file containing the decomposition

flexeme "$repository" "$commit" "$sourcepath" "$classpath" "$output_file"
