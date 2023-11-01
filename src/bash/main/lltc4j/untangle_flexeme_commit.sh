#!/bin/bash
# Untangle with Flexeme on a bug-fixing commit from the Line-Labelled Tangled Commits for Java (LLTC4J) dataset.
# Arguments:
# - $1: URL of the project's git repository. e.g., https://github.com/Thomsch/untangling-tools-benchmark.
# - $2: The commit hash of the bug-fix.
# - $3: Root directory containing all the results of the evaluation.
# - $4: Java sourcepath to use for the compilation.
# - $5: Java classpath to use for the compilation.

# The output of Flexeme is stored in $results_dir/decomposition/flexeme/<commit>/.
# The untangling results are stored in $results_dir/evaluation/<commit>/
# - flexeme.csv: The untangling results in CSV format.
# - flexeme_time.csv: Time spent to untangle the commit.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 5 ] ; then
    echo "usage: $0 <project_vcs_url> <commit_hash> <results_dir> <sourcepath> <classpath>"
    exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPTDIR/lltc4j_util.sh"

vcs_url="$1"
commit_hash="$2"
results_dir="$3"
sourcepath="$4"
classpath="$5"

project_name=$(get_project_name_from_url "$vcs_url")
short_commit_hash="${commit_hash:0:6}"

mkdir -p "$results_dir" # Create the root directory if it doesn't exists yet.

# SmartCommit outputs the untangling results in a subfolder named after the repository name and commit hash.
# so the results will be stored in results_dir/decomposition/smartcommit/<project_name>/<commit_hash>.
export smartcommit_untangling_root_dir="${results_dir}/decomposition/smartcommit"
export flexeme_untangling_dir="${results_dir}/decomposition/flexeme"
export smartcommit_result_dir="${smartcommit_untangling_root_dir}/${project_name}/${commit_hash}"
export respository_dir="${results_dir}/repositories/${project_name}" # repository is named after the project.
export commit_result_dir="${results_dir}/evaluation/${project_name}_${short_commit_hash}" # Directory where the parsed untangling results are stored.

flexeme_untangling_results="${flexeme_untangling_dir}/${project_name}_${short_commit_hash}"
flexeme_untangling_graph="${flexeme_untangling_results}/flexeme.dot"

export flexeme_parse_out="${commit_result_dir}/flexeme.csv"
export smartcommit_parse_out="${commit_result_dir}/smartcommit.csv"
export untangling_time_out="${commit_result_dir}/flexeme_time.csv"

mkdir -p "$flexeme_untangling_dir"
mkdir -p "$flexeme_untangling_results"

echo ""
echo "Untangling project_name $vcs_url, revision ${short_commit_hash}"  >&2

# Clone the repo if it doesn't exist
if [ ! -d "${respository_dir}" ] ; then
  mkdir -p "$respository_dir"
  git clone "$vcs_url" "$respository_dir"
fi

cd "$respository_dir" || exit 1
git checkout "$commit_hash"
cd - || exit 1
echo ""

mkdir -p "$commit_result_dir" # Create the directory where the time statistics will be stored.

if [ -f "$flexeme_untangling_graph" ]; then
  echo 'Untangling with Flexeme .............................................. CACHED'
  untangling_exit_code=0
else
  echo 'Untangling with Flexeme ..............................................'
  START_UNTANGLING="$(date +%s.%N)"
  if ./src/bash/main/untangle_flexeme.sh "$respository_dir" "$commit_hash" "$sourcepath" "$classpath" "${flexeme_untangling_graph}"
  then
    END_UNTANGLING="$(date +%s.%N)"
    ELAPSED="$(echo "$END_UNTANGLING - $START_UNTANGLING" | bc)"
    echo "${project_name},${short_commit_hash},flexeme,${ELAPSED}" > "${untangling_time_out}"
    echo 'Untangling with Flexeme .............................................. OK'
    untangling_exit_code=0
  else
    echo 'Untangling with Flexeme .............................................. FAIL'
    untangling_exit_code=5
  fi
fi

if [ -f "$flexeme_parse_out" ]; then
  echo -ne 'Parsing Flexeme results .............................................. CACHED\r'
  exit 0
fi

if [ $untangling_exit_code -eq 0 ]; then
  echo 'Parsing Flexeme results ..............................................'
  if python3 src/python/main/flexeme_results_to_csv.py "$flexeme_untangling_graph" "$flexeme_parse_out"
  then
      echo 'Parsing Flexeme results .............................................. OK'
      untangling_exit_code=0
  else
      echo 'Parsing Flexeme results .............................................. FAIL'
      untangling_exit_code=6
  fi
fi

exit $untangling_exit_code
