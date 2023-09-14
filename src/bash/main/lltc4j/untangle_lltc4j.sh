#!/bin/bash
# Untangle with SmartCommit and Flexeme on one Line-Labelled Tangled Commits for Java (LLTC4J) bug-fixing commit.
# Arguments:
# - $1: The path to the project clone.
# - $2: The commit hash of the bug-fix.
# - $3: Directory where the results will be stored.

# The decomposition results are written to decomposition/smartcommit/<D4J bug>/ and ~/decomposition/<D4J bug>/flexeme/<D4J bug>/ subfolder.
# - smartcommit/diffs: JSON files storing SmartCommit hunk-based decomposition results
# - smartcommit/time.csv: Run time allocated for untangling by SmartCommit

set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

. .env


if [ $# -ne 3 ] ; then
    echo 'usage: untangle_lltc4j.sh <project_clone_dir> <commit_fix> <out_dir>'
    exit 1
fi

# Returns the project name from an URL.
get_project_name_from_url() {
  local url="$1"
  local filename="${url##*/}"
  local basename="${filename%%.*}"
  echo "$basename"
}

vcs_url="$1"
commit_fix="$2"
out_dir="$3"

project=$(get_project_name_from_url "$vcs_url")
short_commit_fix="${commit_fix:0:6}"

# Initialize exit code variable
export decompose_exit_code=0
# Make Flexeme deterministic
export PYTHONHASHSEED=0
# Path containing the evaluation results. i.e., ground truth, decompositions in CSV format.
export evaluation_path="${out_dir}/evaluation/${project}_${short_commit_fix}"
export decomposition_path="${out_dir}/decomposition"
export smartcommit_untangling_path="${out_dir}/decomposition/smartcommit"
export projects_dir="${out_dir}/projects"

mkdir -p "$out_dir"
mkdir -p "$evaluation_path"
mkdir -p "$decomposition_path"
mkdir -p "$smartcommit_untangling_path"
mkdir -p "$projects_dir"

echo ""
echo "Untangling project $vcs_url, revision ${short_commit_fix}"

project_clone_dir="${projects_dir}/${project}"

# If D4J bug repository does not exist, checkout the D4J bug to repository and
# generates 6 artifacts for it.
if [ ! -d "${project_clone_dir}" ] ; then
  git clone "$vcs_url" "$project_clone_dir"
fi

cd "$project_clone_dir" || exit 1
git checkout "$commit_fix"
cd - || exit 1

echo ""
smartcommit_untangling_results_dir="${smartcommit_untangling_path}/placeholder-project/${short_commit_fix}"

# Untangle with SmartCommit
if [ -d "$smartcommit_untangling_results_dir" ]; then
  echo 'Untangling with SmartCommit ............................................. CACHED'
  regenerate_results=false
else
  echo 'Untangling with SmartCommit ...............................................'
  START_DECOMPOSITION="$(date +%s.%N)"
  "${JAVA11_HOME}/bin/java" -jar lib/smartcommitcore-1.0-all.jar -r "$project_clone_dir" -c "$commit_fix" -o "$smartcommit_untangling_path"
  END_DECOMPOSITION="$(date +%s.%N)"
  DIFF_DECOMPOSITION="$(echo "$END_DECOMPOSITION - $START_DECOMPOSITION" | bc)"
  echo "${project},${short_commit_fix},smartcommit,${DIFF_DECOMPOSITION}" > "${smartcommit_untangling_results_dir}/time.csv"
  echo 'Untangling with SmartCommit ............................................... OK'
#  regenerate_results=true
fi

# Retrieve untangling results from SmartCommit and parse them into a CSV file.
echo ""

#smartcommit_result_out="${evaluation_path}/smartcommit.csv"
#if [ -f "$smartcommit_result_out" ] && [ $regenerate_results = false ]; then
#  echo 'Parsing SmartCommit results ............................................. CACHED'
#else
#  echo 'Parsing SmartCommit results ...............................................'
#  if python3 src/python/main/smartcommit_results_to_csv.py "${smartcommit_untangling_path}/${project}_${short_commit_fix}/${commit_fix}" "$smartcommit_result_out"
#  then
#      echo 'Parsing SmartCommit results ............................................... OK'
#  else
#      echo -ne 'Parsing SmartCommit results ............................................. FAIL'
#      decompose_exit_code=1
#  fi
#fi

exit $decompose_exit_code
