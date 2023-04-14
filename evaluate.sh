#!/bin/bash
# Evaluates a single Defects4j bug.

if [[ $# -ne 4 ]] ; then
    echo 'usage: evaluate.sh <D4J Project> <D4J Bug id> <out_dir> <repo_root>'
    echo 'example: evaluate.sh Lang 1 out/ repositories/'
    exit 1
fi

project=$1
vid=$2
out_path=$3 # Path where the results are stored.
repo_root=$4 # Path where the repo is checked out
workdir="${repo_root}/${project}_${vid}"

decomposition_path="${out_path}/decomposition" # Path containing the decomposition results.
evaluation_path="${out_path}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground
# truth, decompositions in CSV format.
metrics_path="${out_path}/metrics" # Path containing the commit metrics.

mkdir -p "${evaluation_path}"
mkdir -p "${metrics_path}"

set -o allexport
source .env
set +o allexport

# Check that Java is 1.8 for Defects4j.
# Defects4J will use whatever is on JAVA_HOME.
version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)
if [[ $(echo "$version != 1.8" | bc) == 1 ]] ; then
    echo "Unsupported Java Version: ${version}. Please use Java 8."
    exit 1
fi

echo "Evaluating project $project, bug $vid, repository $workdir"

# Checkout Defects4J bug
mkdir -p "$workdir"
defects4j checkout -p "$project" -v "$vid"b -w "$workdir"

# Get commit hash
commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)

# Get source path and class path
sourcepath=$(defects4j export -p dir.src.classes -w "${workdir}")
sourcepath="${sourcepath}:$(defects4j export -p dir.src.tests -w "${workdir}")"

classpath=$(defects4j export -p cp.compile -w "${workdir}")
classpath="${classpath}:$(defects4j export -p cp.test -w "${workdir}")"

#
# Compute commit metrics
#
metrics_out="${metrics_path}/${project}_${vid}.csv" # Metrics for this bug
if [[ -f "$metrics_out" ]]; then
    echo -ne 'Calculating metrics ..................................................... SKIP\r'
else
    source ./scripts/diff_util.sh
    diff "$project" "$vid" "$commit" "$workdir" | python3 src/commit_metrics.py "${project}" "${vid}" > "$metrics_out"
    code=$?
    if [ $code -eq 0 ]
    then
        echo -ne 'Calculating metrics ..................................................... OK\r'
    else
        echo -ne 'Calculating metrics ..................................................... FAIL\r'
    fi
fi

#
# Calculates the ground truth
#
echo -ne '\n'
echo -ne 'Calculating ground truth ..................................................\r'

truth_out="${evaluation_path}/truth.csv"

if [[ -f "$truth_out" ]]; then
    echo -ne 'Calculating ground truth ................................................ SKIP\r'
else
    ./scripts/ground_truth.sh "$project" "$vid" "$workdir" "$truth_out" "$commit"
    code=$?
    if [ $code -eq 0 ]
    then
        echo -ne 'Calculating ground truth .................................................. OK\r'
    else
        echo -ne 'Calculating ground truth .................................................. FAIL\r'
    fi
fi
echo -ne '\n'

#
# Running each tool on the bug.
# Tools are run in serial, but could be run in parallel. The results are ouputted to invididual files, enabling parallelisation.
#
# TODO: Run tools in parallel. See https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
#

#
# Untangle with SmartCommit
#
echo -ne '\n'
echo -ne 'Untangling with SmartCommit ...............................................\r'
smartcommit_untangling_path="${out_path}/decomposition/smartcommit"
smartcommit_untangling_results="${smartcommit_untangling_path}/${project}_${vid}/${commit}"

if [[ -d "$smartcommit_untangling_results" ]]; then
    echo -ne 'Untangling with SmartCommit ............................................. SKIP\r'
    regenerate_results=false
else
    echo -ne '\n'
    START_DECOMPOSITION=$(date +%s.%N)
    $JAVA_SMARTCOMMIT -jar bin/smartcommitcore-1.0-all.jar -r "$workdir" -c "$commit" -o "$smartcommit_untangling_path"
    END_DECOMPOSITION=$(date +%s.%N)
    DIFF_DECOMPOSITION=$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)
    echo "${project},${vid},smartcommit,${DIFF_DECOMPOSITION}" > "${smartcommit_untangling_results}/time.csv"
    echo -ne 'Untangling with SmartCommit ............................................... OK'
    regenerate_results=true
fi
echo -ne '\n'

# Collate untangling results
echo -ne '\n'
echo -ne 'Parsing SmartCommit results ...............................................\r'

smartcommit_result_out="${evaluation_path}/smartcommit.csv"
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

#
# Untangle with Flexeme
#
echo -ne '\n'
echo -ne 'Untangling with Flexeme ...............................................\r'

flexeme_untangling_path="${decomposition_path}/flexeme"
flexeme_untangling_results="${flexeme_untangling_path}/${project}_${vid}"
flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"

if [[ -f "$flexeme_untangling_graph" ]]; then
    echo -ne 'Untangling with Flexeme ................................................. SKIP\r'
    regenerate_results=false
else
    echo -ne '\n'
    mkdir -p "$flexeme_untangling_results"
    START_DECOMPOSITION=$(date +%s.%N)
    ./scripts/untangle_flexeme.sh "$workdir" "$commit" "$sourcepath" "$classpath" "${flexeme_untangling_graph}"
    flexeme_untangling_code=$?
    if [ $flexeme_untangling_code -eq 0 ]
    then
        echo -ne 'Untangling with Flexeme ................................................. OK'
        regenerate_results=true
    else
        echo -ne 'Untangling with Flexeme ................................................. FAIL'
        regenerate_results=false
    fi
    END_DECOMPOSITION=$(date +%s.%N)
    DIFF_DECOMPOSITION=$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)
    echo "${project},${vid},flexeme,${DIFF_DECOMPOSITION}" > "${flexeme_untangling_results}/time.csv"

fi
echo -ne '\n'

# Collate untangling results
echo -ne 'Parsing Flexeme results ...............................................\r'

flexeme_result_out="${evaluation_path}/flexeme.csv"
if [ ${flexeme_untangling_code:-1} -ne 0 ] || { [ -f "$flexeme_result_out" ] && [ $regenerate_results == false ]; } ;
then
    echo -ne 'Parsing Flexeme results ................................................. SKIP\r'
else
    echo -ne '\n'
    python3 src/parse_flexeme_results.py "$flexeme_untangling_graph" "$flexeme_result_out"
    code=$?

    if [ $code -eq 0 ]
    then
        echo -ne 'Parsing Flexeme results ................................................... OK\r'
    else
        echo -ne 'Parsing Flexeme results ................................................. FAIL\r'
    fi
    echo -ne '\n'
fi

#
# Compute untangling score
#
echo -ne 'Computing untangling scores ...............................................\r'
python3 src/untangling_score.py "$evaluation_path" "${project}" "${vid}" > "${evaluation_path}/scores.csv"
echo -ne 'Computing untangling scores ............................................ OK'

# # rm -rf "$workdir" # Deletes temporary directory containing repository

# # TODO: Handle failure for truth step and decomposition step.
