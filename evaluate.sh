#!/bin/bash

project=$1
vid=$2
export DEFECTS4J_HOME="/Users/thomas/Workplace/defects4j"
export JAVA_HOME="/Users/thomas/.jenv/versions/11.0/bin/java"

echo "Evaluating project $project, bug $vid"

workdir=./tmp/"$project"_"$vid"

mkdir -p "./tmp" # Create temporary directory

# Checkout defects4j bug
defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)
echo "Commit: ${commit}"

# Calculates the ground truth
echo -ne '\n'
echo -ne 'Calculating ground truth ..................................................\r'
./scripts/ground_truth.sh "$project" "$vid" "$workdir" ./out/evaluation/"$project"/"$vid"/truth.csv
echo -ne 'Calculating ground truth .................................................. OK\r'
echo -ne '\n'

# Run untangling tools in separate processes.
echo -ne '\n'
echo -ne 'Untangling with SmartCommit ...............................................\r'
echo -ne '\n'

smartcommit_out="./out/decomposition/smartcommit"
$JAVA_HOME -jar bin/smartcommitcore-1.0-all.jar -r "$workdir" -c "$commit" -o $smartcommit_out
# TODO: Run approaches in parallel. 
# See https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0

echo -ne 'Untangling with SmartCommit ............................................... OK'
echo -ne '\n'

# Collate untangling results
echo -ne '\n'
echo -ne 'Parsing SmartCommit results ...............................................\n'
smartcommit_result_out="./out/evaluation/${project}/${vid}/smartcommit.csv"
python3 parse_smartcommit_results.py "${smartcommit_out}/${project}_${vid}/${commit}" "$smartcommit_result_out"
code=$?

if [ $code -eq 0 ] 
then 
    echo -ne 'Parsing SmartCommit results ............................................... OK'
else 
    echo -ne 'Parsing SmartCommit results ............................................. FAIL'
fi
echo -ne '\n'

# rm -rf "$workdir" # Deletes temporary directory