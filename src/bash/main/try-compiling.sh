#!/bin/bash
# Try to compile the projects at a given commit hash from a given file.
# Arguments:
# - $1: The file containing the commits.
# - $2: The output directory where the projects will be cloned and compiled.
#
# The results are written to stdout in CSV format with the following columns:
# - Name of the project
# - Commit hash (abbreviated to 6 characters)
# - Compilation status. Can be either "FAIL", "JAVA8", or "COMMIT_NOT_FOUND".
# - Time elapsed. In seconds, rounded to the nearest integer.
#
# Each version of the project is cloned in a directory named after the project
# in the output directory. Details error message and execution log is written to
# 'compile.log' for each project directory.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: decompose.sh <commits> <out_dir>'
    exit 1
fi

export commits="$1" # The file containing the bugs to untangle.
export out_dir="$2"

if ! [ -f "$commits" ]; then
    echo "$0: file ${commits} not found. Exiting."
    exit 1
fi

if ! [ -d "$out_dir" ]; then
    echo "$0: directory ${out_dir} not found. Exiting."
    exit 1
fi

untangle_with_tools(){
  local project_name="$1"
  local vcs_url="$2"
  local commit_hash="$3"
  local short_commit_fix="${commit_hash:0:6}"

  repository="${out_dir}/projects/${project_name}"

  # TODO: Find a way to speed this up.
  # IDEA1: Use a local clone of the repository.
  START="$(date +%s.%N)"
  git clone -q "$vcs_url" "$repository" || exit 1
  cd "$repository" || exit 1
  git checkout -q "$commit_hash"
  ret_code=$?
  cd - >/dev/null || exit 1
  if [ $ret_code -ne 0 ]; then
    untangling_status_string="COMMIT_NOT_FOUND"
  fi

  if [ -z "$untangling_status_string" ]; then
    # TODO: Try running on multiple versions of Java.
    java_version="JAVA8"
    src/bash/main/compile-project.sh "${repository}" > "${repository}/compile.log" 2>&1
    ret_code=$?
    untangling_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "$java_version")"
  fi

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%s,%s,%s,%.0fs\n" "${project_name}" "${short_commit_fix}" "${untangling_status_string}" "${ELAPSED}"
}

export -f untangle_with_tools
printf "%s,%s,%s,%s\n" "project_name" "commit_hash" "compilation_status" "elapsed_time"
tail -n+2 "$commits" | parallel --colsep "," untangle_with_tools {}
