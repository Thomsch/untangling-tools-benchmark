#!/bin/bash
# Translates SmartCommit results (JSON files) and Flexeme graphs ().dot files) in decomposition/D4J_bug for each D4J bug
# file to the line level. Each line is labelled with the group it belongs to and this is reported in
# a readable CSV file. Then, calculates the Rand Index for untangling results of 3 methods: SmartCommit, Flexeme, and File-based.
# - $1: D4J Project name
# - $2: D4J Bug id
# - $3: Path to the checked out project repository
# - $4: The path where to output the results

# Results are outputted to evaluation/<D4J_bug> subfolder.
# Writes parsed decomposition results to smartcommit.csv and flexeme.csv in /evaluation/<D4J_bug>
# Writes Rand Index scores computed to /evaluation/<D4J_bug>/scores.csv

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

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

decomposition_path="${out_path}/decomposition" # Path containing the decomposition results.
evaluation_path="${out_path}/evaluation/${project}_${vid}" # Path containing the evaluation results

flexeme_untangling_path="${decomposition_path}/flexeme"
flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"
smartcommit_untangling_path="${out_path}/decomposition/smartcommit"

commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)

#
# Retrieve untangling results from SmartCommit and parse them into a CSV file.
#
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
# Retrieve untangling results from Flexeme and parse them into a CSV file.
#
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