#!/bin/bash
#
# Runs SmartCommit for one bug
# Outputs: one line of CSV data in the console
#
# WIP: The commands are for reference only for now, the script will not work by itself.
#

#repository=""
#commit=""
work_dir="./tmp"
revision_id="687b2e62"
defects4j_framework="/Users/thomas/Workplace/defects4j/framework"

# Checkout bug-fixing commit from developer
# checkout_bug_fix.sh

# Decompose bug-fixing commit
# java -jar bin/smartcommitcore-1.0-all.jar -r "workdir" -c "687b2e62" -o "./out/smartcommit/"

# Get the changed lines in each group automatically decomposed
# python3 retrieve_changed_lines.py ./out/smartcommit/workdir/687b2e62/generated_groups/

# Get the minimal bug-fixing changes (ground truth)
# ./minimal_fix.sh

# Calculates precision and recall for bug-fixing changes and non bug-fixing changes.
# TBD