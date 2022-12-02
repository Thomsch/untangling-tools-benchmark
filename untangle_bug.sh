#!/bin/bash

################################
# Runs SmartCommit for one bug
# Outputs: one line of CSV data in the console
#
# WIP: The commands are for reference only for now, the script will not work by itself.
################################

#repository=""
#commit=""
work_dir="./tmp"
revision_id="687b2e62"
defects4j_framework="/Users/thomas/Workplace/defects4j/framework"



# Get changes from decomposition.
git clone "/Users/thomas/Workplace/defects4j/project_repos/commons-lang.git" "$work_dir" 2>&1 && cd "$work_dir" && git checkout $revision_id 2>&1 # Probably better to use defects4j checkout to avoid broken stuff. Checkout the tag.
#java -jar bin/smartcommitcore-1.0-all.jar -r "workdir" -c "687b2e62" -o "./out/smartcommit/"

## Read out/smartcommit/repo/generated_groups/
## Performance could be improved by building the table of hunk ids and files only once and looking at all the groups then.
for f in ./out/smartcommit/workdir/687b2e62/generated_groups/*.json
do
  echo "Processing $f file..."
  python3 export_group.py "$f"
done

# #G1.csv
# class, line
# class, line
# class, line

# #G2.csv
# class, line
# class, line
# class, line