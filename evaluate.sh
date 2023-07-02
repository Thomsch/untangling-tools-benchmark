#!/bin/bash
# Run the untangling tools on a single Defects4J (D4J) bug. Also calculates the bug's metrics and parse the bug's manual
# untangling into a CSV file.
# - $1: D4J Project name
# - $2: D4J Bug Id
# - $3: Path where the results are stored.
# - $4: Path where the repo is checked out

# Output: evaluate.sh calls the following scripts in order on each bug file, please refer to the particular script for detailed documentation of input & output:
# - src/python/main/commit_metrics.py returns commit metrics in /metrics
# - src/bash/main/ground_truth.sh returns ground truth in /evaluation/truth.csv
# - src/python/main/filename_untangling.py returns file-based untangling results in evaluation/file_untangling.csv
# - bin/smartcommitcore-1.0-all.jar returns SmartCommit untangling results in decomposition/smartcommit
# - src/python/main/parse_smartcommit_results.py returns collated SmartCommit results in evaluation/smartcommit.csv
# - src/bash/main/untangle_flexeme.sh returns Flexeme untangling results in /decomposition/flexeme
# - src/python/main/parse_flexeme_results.py returns collated Flexeme untangling results in evaluation/flexeme.csv
# - src/python/main/untangling_score.py returns untangling scores in evaluation/scores.csv

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

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

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

if [[ -z "${JAVA_11}" ]]; then
  echo 'JAVA_11 environment variable is not set.'
  echo 'Please set it to the path of a Java 11 java.'
  exit 1
fi

decomposition_path="${out_path}/decomposition" # Path containing the decomposition results.
evaluation_path="${out_path}/evaluation/${project}_${vid}" # Path containing the evaluation results. i.e., ground
# truth, decompositions in CSV format.
metrics_path="${out_path}/metrics" # Path containing the commit metrics.

mkdir -p "${evaluation_path}"
mkdir -p "${metrics_path}"

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
commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)    # Commit hash is the revision_fixed_ID

# Get source path and class path
sourcepath=$(defects4j export -p dir.src.classes -w "${workdir}")
sourcepath="${sourcepath}:$(defects4j export -p dir.src.tests -w "${workdir}")"

classpath=$(defects4j export -p cp.compile -w "${workdir}")
classpath="${classpath}:$(defects4j export -p cp.test -w "${workdir}")"

#
# Generate six artifacts (three unified diffs, three source code files)
# 
bug_fix_diff_out="${workdir}/diff/bug_fix.diff"

if [[ -f "$bug_fix_diff_out" ]]; then
    echo -ne 'Generating diff and code artifacts ................................................ CACHED\r'
else
    ./src/bash/main/generate_artifacts.sh "$project" "$vid" "$workdir"
    code=$?
    if [ $code -eq 0 ]
    then
        echo -ne 'Generating diff and code artifacts .................................................. OK\r'
    else
        echo -ne 'Generating diff and code artifacts .................................................. FAIL\r'
    fi
fi
echo -ne '\n'

#
# Compute commit metrics
#
metrics_csv="${metrics_path}/${project}_${vid}.csv" # Metrics for this bug
if [[ -f "$metrics_csv" ]]; then
    echo -ne 'Calculating metrics ..................................................... CACHED\r'
else
    source ./src/bash/main/d4j_utils.sh

    # Parse the returned result into two variables
    result=$(retrieve_revision_ids "$project" "$vid")
    read -r revision_buggy revision_fixed <<< "$result"

    d4j_diff "$project" "$vid" "$revision_buggy" "$revision_fixed" "$workdir" | python3 src/python/main/commit_metrics.py "${project}" "${vid}" > "$metrics_csv"
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

truth_csv="${evaluation_path}/truth.csv"

if [[ -f "$truth_csv" ]]; then
    echo -ne 'Calculating ground truth ................................................ CACHED\r'
else
    ./src/bash/main/ground_truth.sh "$project" "$vid" "$workdir" "$truth_csv"
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

## TODO: Rather than duplicating code, which is error-prone, use a for loop to run all of the tools.

#
# Untangle with file-based approach
#
echo -ne '\n'
echo -ne 'Untangling with file-based approach .........................................\r'

file_untangling_out="${evaluation_path}/file_untangling.csv"

if [[ -f "$file_untangling_out" ]]; then
    echo -ne 'Untangling with file-based approach ..................................... CACHED\r'
else
    python3 src/python/main/filename_untangling.py "${truth_csv}" "${file_untangling_out}"
    code=$?
    if [ $code -eq 0 ]
    then
        echo -ne 'Untangling with file-based approach ....................................... OK\r'
    else
        echo -ne 'Untangling with file-based approach ..................................... FAIL\r'
    fi
fi
echo -ne '\n'

#
# Untangle with SmartCommit
#
echo -ne '\n'
echo -ne 'Untangling with SmartCommit ...............................................\r'
smartcommit_untangling_path="${out_path}/decomposition/smartcommit"
smartcommit_untangling_results="${smartcommit_untangling_path}/${project}_${vid}/${commit}"

if [[ -d "$smartcommit_untangling_results" ]]; then
    echo -ne 'Untangling with SmartCommit ............................................. CACHED\r'
    regenerate_results=false
else
    echo -ne '\n'
    START_DECOMPOSITION=$(date +%s.%N)
    $JAVA_11 -jar bin/smartcommitcore-1.0-all.jar -r "$workdir" -c "$commit" -o "$smartcommit_untangling_path"
    END_DECOMPOSITION=$(date +%s.%N)
    DIFF_DECOMPOSITION=$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)
    echo "${project},${vid},smartcommit,${DIFF_DECOMPOSITION}" > "${smartcommit_untangling_results}/time.csv"
    echo -ne 'Untangling with SmartCommit ............................................... OK'
    regenerate_results=true
fi

# Collate untangling results
echo -ne '\n'
echo -ne 'Parsing SmartCommit results ...............................................\r'

smartcommit_result_out="${evaluation_path}/smartcommit.csv"
if [ -f "$smartcommit_result_out" ] && [ $regenerate_results == false ]; then
    echo -ne 'Parsing SmartCommit results ............................................. CACHED\r'
else
    echo -ne '\n'
    python3 src/python/main/parse_smartcommit_results.py "${smartcommit_untangling_path}/${project}_${vid}/${commit}" "$smartcommit_result_out"
    code=$?

    if [ $code -eq 0 ]
    then
        echo -ne 'Parsing SmartCommit results ............................................... OK'
    else
        echo -ne 'Parsing SmartCommit results ............................................. FAIL'
    fi
    echo -ne '\n'
fi
echo -ne '\n'

#
# Untangle with Flexeme
#
echo -ne '\n'
echo -ne 'Untangling with Flexeme ...............................................\r'

flexeme_untangling_path="${decomposition_path}/flexeme"
flexeme_untangling_results="${flexeme_untangling_path}/${project}_${vid}"
flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"

if [[ -f "$flexeme_untangling_graph" ]]; then
    echo -ne 'Untangling with Flexeme ................................................. CACHED\r'
    regenerate_results=false
else
    echo -ne '\n'
    mkdir -p "$flexeme_untangling_results"
    START_DECOMPOSITION=$(date +%s.%N)
    ./src/bash/main/untangle_flexeme.sh "$workdir" "$commit" "$sourcepath" "$classpath" "${flexeme_untangling_graph}"
    flexeme_untangling_code=$?
    if [ $flexeme_untangling_code -eq 0 ]
    then
        echo -ne 'Untangling with Flexeme ................................................... OK'
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
if [ "${flexeme_untangling_code:-1}" -ne 0 ] || { [ -f "$flexeme_result_out" ] && [ $regenerate_results == false ]; } ;
then
    echo -ne 'Parsing Flexeme results ................................................. CACHED\r'
else
    echo -ne '\n'
    python3 src/python/main/parse_flexeme_results.py "$flexeme_untangling_graph" "$flexeme_result_out"
    code=$?

    if [ $code -eq 0 ]
    then
        echo -ne 'Parsing Flexeme results ................................................... OK\r'
    else
        echo -ne 'Parsing Flexeme results ................................................. FAIL\r'
    fi
    echo -ne '\n'
fi
echo -ne '\n'


#
# Compute untangling score
#
echo -ne '\n'
echo -ne 'Computing untangling scores ...............................................\r'
python3 src/python/main/untangling_score.py "$evaluation_path" "${project}" "${vid}" > "${evaluation_path}/scores.csv"
echo -ne 'Computing untangling scores ............................................... OK'
echo -ne '\n'
