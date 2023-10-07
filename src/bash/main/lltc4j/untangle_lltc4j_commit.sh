#!/bin/bash
# Untangle with SmartCommit on a bug-fixing commit from the Line-Labelled Tangled Commits for Java (LLTC4J) dataset.
# Arguments:
# - $1: The path to the project_name clone.
# - $2: The commit hash of the bug-fix.
# - $3: Directory where the results will be stored.

# The decomposition results are written to decomposition/smartcommit/<D4J bug>/ and ~/decomposition/<D4J bug>/flexeme/<D4J bug>/ subfolder.
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time spent by SmartCommit

set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 3 ] ; then
    echo 'usage: untangle_lltc4j_commit.sh <project_vcs_url> <commit_hash> <out_dir>'
    exit 1
fi

# Returns the project name from a URL.
get_project_name_from_url() {
  local url="$1"
  local filename="${url##*/}"
  local basename="${filename%%.*}"
  echo "$basename"
}

vcs_url="$1"
commit_hash="$2"
out_dir="$3"

project_name=$(get_project_name_from_url "$vcs_url")
short_commit_hash="${commit_hash:0:6}"

export smartcommit_untangling_results_dir="${out_dir}/decomposition/smartcommit/${project_name}_${short_commit_hash}"
export project_clone_dir="${out_dir}/projects/${project_name}"

mkdir -p "$out_dir"

echo ""
echo "Untangling project_name $vcs_url, revision ${short_commit_hash}"

# Clone the repo if it doesn't exist
if [ ! -d "${project_clone_dir}" ] ; then
  mkdir -p "$project_clone_dir"
  git clone "$vcs_url" "$project_clone_dir"
fi

cd "$project_clone_dir" || exit 1
git checkout "$commit_hash"
cd - || exit 1

echo ""

# Untangle with SmartCommit
if [ -d "$smartcommit_untangling_results_dir" ]; then
  echo 'Untangling with SmartCommit .......................................... CACHED'
else
  echo 'Untangling with SmartCommit ..........................................'
  START_DECOMPOSITION="$(date +%s.%N)"
  "${JAVA11_HOME}/bin/java" -jar lib/smartcommitcore-1.0-all.jar -r "$project_clone_dir" -c "$commit_hash" -o "$smartcommit_untangling_results_dir"
  END_DECOMPOSITION="$(date +%s.%N)"
  DIFF_DECOMPOSITION="$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)"
  mkdir -p smartcommit_untangling_results_dir
  echo "${project_name},${short_commit_hash},smartcommit,${DIFF_DECOMPOSITION}" > "${smartcommit_untangling_results_dir}/time.csv"
  echo 'Untangling with SmartCommit .......................................... DONE'
fi


# Retrieve untangling results from SmartCommit and parse them into a CSV file.
echo ""
smartcommit_result_out="${smartcommit_untangling_results_dir}/smartcommit.csv"
if [ -f "$smartcommit_result_out" ] ; then
  echo 'Parsing SmartCommit results .......................................... CACHED'
  decompose_exit_code=0
else
  echo 'Parsing SmartCommit results ..........................................'
  if python3 src/python/main/smartcommit_results_to_csv.py "${smartcommit_untangling_results_dir}/${project_name}/${commit_hash}" "$smartcommit_result_out"
  then
      echo 'Parsing SmartCommit results .......................................... OK'
      decompose_exit_code=0
  else
      echo 'Parsing SmartCommit results .......................................... FAIL'
      decompose_exit_code=1
  fi
fi

exit $decompose_exit_code
