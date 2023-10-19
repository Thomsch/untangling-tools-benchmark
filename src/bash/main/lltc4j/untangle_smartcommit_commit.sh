#!/bin/bash
# Untangle with SmartCommit on a bug-fixing commit from the Line-Labelled Tangled Commits for Java (LLTC4J) dataset.
# Arguments:
# - $1: URL of the project's git repository. e.g., https://github.com/Thomsch/untangling-tools-benchmark.
# - $2: The commit hash of the bug-fix.
# - $3: Root directory containing all the results of the evaluation.

# The output of Smartcommit is stored in $results_dir/decomposition/smartcommit/<commit>/.
# The untangling results are stored in $results_dir/evaluation/<commit>/
# - smartcommit.csv: The untangling results in CSV format.
# - smartcommit_time.csv.csv: Time spent to untangle the commit.

set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 3 ] ; then
    echo 'usage: untangle_smartcommit_commit.sh <project_vcs_url> <commit_hash> <results_dir>'
    exit 1
fi

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPTDIR/lltc4j_util.sh"

vcs_url="$1"
commit_hash="$2"
results_dir="$3"

project_name=$(get_project_name_from_url "$vcs_url")
short_commit_hash="${commit_hash:0:6}"

mkdir -p "$results_dir" # Create the root directory if it doesn't exists yet.

# SmartCommit outputs the untangling results in a subfolder named after the repository name and commit hash.
# so the results will be stored in results_dir/decomposition/smartcommit/<project_name>/<commit_hash>.
export smartcommit_untangling_root_dir="${results_dir}/decomposition/smartcommit"
export smartcommit_commit_result_dir="${smartcommit_untangling_root_dir}/${project_name}/${commit_hash}"
export respository_dir="${results_dir}/repositories/${project_name}" # repository is named after the project.
export commit_result_dir="${results_dir}/evaluation/${project_name}_${short_commit_hash}" # Directory where the parsed untangling results are stored.

export smartcommit_parse_out="${commit_result_dir}/smartcommit.csv"
export untangling_time_out="${commit_result_dir}/smartcommit_time.csv"

echo ""
echo "Untangling project_name $vcs_url, revision ${short_commit_hash}"

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

# Untangle with SmartCommit
if [ -d "$smartcommit_commit_result_dir" ]; then
  echo 'Untangling with SmartCommit ............................................. CACHED'
else
  echo 'Untangling with SmartCommit ...............................................'
  START_DECOMPOSITION="$(date +%s.%N)"
  "${JAVA11_HOME}/bin/java" -jar lib/smartcommitcore-1.0-all.jar -r "$respository_dir" -c "$commit_hash" -o "${smartcommit_untangling_root_dir}"
  END_DECOMPOSITION="$(date +%s.%N)"
  DIFF_DECOMPOSITION="$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)"
  echo "${project_name},${short_commit_hash},smartcommit,${DIFF_DECOMPOSITION}" > "${untangling_time_out}"
  echo 'Untangling with SmartCommit ............................................... OK'
fi


# Retrieve untangling results from SmartCommit and parse them into a CSV file.
echo ""
if [ -f "$smartcommit_parse_out" ] ; then
  echo 'Parsing SmartCommit results ............................................. CACHED'
  decompose_exit_code=0
else
  echo 'Parsing SmartCommit results ...............................................'
  if python3 src/python/main/smartcommit_results_to_csv.py "${smartcommit_commit_result_dir}" "$smartcommit_parse_out"
  then
      echo 'Parsing SmartCommit results ............................................... OK'
      decompose_exit_code=0
      echo -ne 'Parsing SmartCommit results ............................................. FAIL'
  else
      decompose_exit_code=1
  fi
fi

exit $decompose_exit_code