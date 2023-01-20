#!/bin/bash
# Evaluates a single Defects4j bug.

# Arguments: ./evaluate.sh <project_id> <bug id>
# e.g., ./evaluate.sh Lang 1
project=$1
vid=$2
out_path=$3

export DEFECTS4J_HOME="/Users/thomas/Workplace/defects4j"
export JAVA_HOME="/Users/thomas/.jenv/versions/11.0/bin/java"

echo "Evaluating project $project, bug $vid"

workdir=./tmp/"$project"_"$vid"

mkdir -p "./tmp" # Create temporary directory

# Checkout defects4j bug
defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)
echo "Commit: ${commit}"

# Create directories
mkdir -p "./out/evaluation/${project}/${vid}"

# Calculates the ground truth
echo -ne '\n'
echo -ne 'Calculating ground truth ..................................................\r'


truth_out="./out/evaluation/${project}/${vid}/truth.csv"

if [[ -f "$truth_out" ]]; then
    echo -ne 'Calculating ground truth ................................................ SKIP\r'
else
    ./scripts/ground_truth.sh "$project" "$vid" "$workdir" "$truth_out" "$commit"
    echo -ne 'Calculating ground truth .................................................. OK\r'
fi
echo -ne '\n'

# Run untangling tools in separate processes.
# TODO: Run approaches in parallel. 
# See https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
# Each tool's output is redirected in a log file.

echo -ne '\n'
echo -ne 'Untangling with SmartCommit ...............................................\r'

smartcommit_untangling_path="./out/decomposition/smartcommit"
smartcommit_untangling_results="${smartcommit_untangling_path}/${project}_${vid}/${commit}"

if [[ -d "$smartcommit_untangling_results" ]]; then
    echo -ne 'Untangling with SmartCommit ............................................. SKIP\r'
    regenerate_results=false
else
    echo -ne '\n'
    $JAVA_HOME -jar bin/smartcommitcore-1.0-all.jar -r "$workdir" -c "$commit" -o $smartcommit_untangling_path
    echo -ne 'Untangling with SmartCommit ............................................... OK'
    regenerate_results=true
fi
echo -ne '\n'

# Collate untangling results
echo -ne '\n'
echo -ne 'Parsing SmartCommit results ...............................................\r'

smartcommit_result_out="./out/evaluation/${project}/${vid}/smartcommit.csv"
if [ -f "$smartcommit_result_out" ] && [ $regenerate_results == false ]; then
    echo -ne 'Parsing SmartCommit results ............................................. SKIP\r'
else
    echo -ne '\n'
    python3 src/parse_smartcommit_results.py "${smartcommit_untangling_path}/${project}_${vid}/${commit}" "$smartcommit_result_out"
    code=$?

    if [ $code -eq 0 ] 
    then 
        echo -ne 'Parsing SmartCommit results ............................................... OK'
    else 
        echo -ne 'Parsing SmartCommit results ............................................. FAIL'
    fi
    echo -ne '\n'
fi

# Compute untangling score
echo -ne '\n'
evaluation_results="./out/evaluation/${project}/${vid}"

python3 src/untangling_score.py "$evaluation_results" "${project}" "${vid}" > "${out_path}/${project}_${vid}.csv"

# Compute commit metrics
echo -ne '\n'

metrics_dir="./out/metrics"
mkdir -p $metrics_dir

git --git-dir="${workdir}/.git" diff -U0 "$commit"^ "$commit" | python3 src/commit_metrics.py "${project}" "${vid}" > "${metrics_dir}/${project}_${vid}.csv"

# rm -rf "$workdir" # Deletes temporary directory containing repository

# TODO: Handle failure for truth step and decomposition step.
# TODO: Measure elapsed time for decomposition and add to CSV