#!/bin/bash
# Given a list of Defects4J (D4J) bugs, the script translates SmartCommit results (JSON files) and Flexeme graphs ().dot files) in decomposition/D4J_bug for each D4J bug
# file to the line level. Each line is labelled with the group it belongs to and this is reported in
# a readable CSV file. Then, calculates the Rand Index for untangling results of 3 methods: SmartCommit, Flexeme, and File-based.
# - $1: Path to the file containing the bugs to untangle and evaluate.
# - $2: Path to the directory where the results are stored and repositories checked out.

# Results are outputted to evaluation/<D4J_bug> respective subfolder.
# Writes parsed decomposition results to smartcommit.csv and flexeme.csv for each bug in /evaluation/<D4J_bug>
# Writes Rand Index scores computed to /evaluation/<D4J_bug>/decomposition_scores.csv

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [[ $# -ne 2 ]] ; then
    echo 'usage: evaluate_all.sh <bugs_file> <out_dir>'
    exit 1
fi

export bugs_file=$1 # Path to the file containing the bugs to untangle and evaluate.
export out_dir=$2 # Path to the directory where the results are stored and repositories checked out.
export evaluation_dir="${out_dir}/evaluation"
export decomposition_dir="${out_dir}/decomposition"

mkdir -p "$evaluation_dir"
mkdir -p "$decomposition_dir"

set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

parse_and_score_bug(){
  local project=$1
  local vid=$2

  decomposition_path="${out_dir}/decomposition" # Path containing the decomposition results.
  evaluation_path="${out_dir}/evaluation/${project}_${vid}" # Path containing the evaluation results
  mkdir -p "${decomposition_path}"
  mkdir -p "${evaluation_path}"
  
  flexeme_untangling_path="${decomposition_path}/flexeme"
  flexeme_untangling_results="${flexeme_untangling_path}/${project}_${vid}"
  flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"
  smartcommit_untangling_path="${out_dir}/decomposition/smartcommit"
  truth_csv="${evaluation_path}/truth.csv"
  commit=$(defects4j info -p "$project" -b "$vid" | grep -A1 "Revision ID" | tail -n 1)

  # Untangle with file-based approach
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

  # Retrieve untangling results from SmartCommit and parse them into a CSV file.
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

  # Retrieve untangling results from Flexeme and parse them into a CSV file.
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

  # Compute untangling score
  echo -ne '\n'
  echo -ne 'Computing untangling scores ...............................................\r'
  python3 src/python/main/untangling_score.py "$evaluation_path" "${project}" "${vid}" > "${evaluation_path}/decomposition_scores.csv"
  echo -ne 'Computing untangling scores ............................................... OK'
  echo -ne '\n'
}

export -f parse_and_score_bug
parallel --colsep "," parse_and_score_bug {} < "$bugs_file"