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

### Get changed lines per group for SmartCommit
# Checkout bug-fixing commit from developer
# checkout_bug_fix.sh

# Decompose bug-fixing commit
# java -jar bin/smartcommitcore-1.0-all.jar -r "workdir" -c "687b2e62" -o "./out/smartcommit/"

# Get the changed lines in each group automatically decomposed
# python3 parse_smartcommit_results.py ./out/smartcommit/workdir/687b2e62/ out/evaluation/lang/1/groups.csv

### Get ground truth
# Get the minimal bug-fixing changes (ground truth)
# ./ground_truth.sh

### Calculates precision and recall for bug-fixing changes and non bug-fixing changes.
# TBD