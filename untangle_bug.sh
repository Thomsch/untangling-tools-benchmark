#!/bin/bash

################################
# Runs SmartCommit for one bug
# WIP: The commands are for reference only for now, the script will not work by itself.
################################

#repository=""
#commit=""
work_dir="./tmp"
revision_id="687b2e62"
defects4j_framework="/Users/thomas/Workplace/defects4j/framework"

# Ground truth:
project="Cli"
vid="1"
# Show patch
cat $defects4j_framework/projects/$project/patches/$vid.src.patch
cat /Users/thomas/Workplace/defects4j/framework/projects/Cli/patches/1.src.patch | ./diff-lines.sh
# Diff-lines is probably not getting the right line numbers (new rather than old file (vn to vbug)).

# Get changes from decomposition.
git clone "/Users/thomas/Workplace/defects4j/project_repos/commons-lang.git" "$work_dir" 2>&1 && cd "$work_dir" && git checkout $revision_id 2>&1 # Probably better to use defects4j checkout to avoid broken stuff. Checkout the tag.
#java -jar bin/smartcommitcore-1.0-all.jar -r "workdir" -c "687b2e62" -o "./out/smartcommit/"