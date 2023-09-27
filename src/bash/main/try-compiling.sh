#!/bin/bash
# Try to compile the projects at a given commit hash from a given file.
# Arguments:
# - $1: Path to the file containing a list of commits to compile.
# - $2: Directory to store project clones.
#
# The results are written to stdout in CSV format with the following columns:
# - Name of the project
# - Commit hash (abbreviated to 6 characters)
# - Compilation status. Shows the java version, or the status tag "FAIL" or "COMMIT_NOT_FOUND".
# - Time elapsed. In seconds, rounded to the nearest integer.
#
# Each version of the project is cloned in a directory named after the project
# commit hash. The execution log 'compile.log' is written at the root of each
# clone.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo 'usage: decompose.sh <commits_file> <clone_dir>'
    exit 1
fi

export commits_file="$1"
export clone_dir="$2"

if ! [ -f "$commits_file" ]; then
    echo "$0: file ${commits_file} not found. Exiting."
    exit 1
fi

if ! [ -d "$clone_dir" ]; then
    echo "$0: directory ${clone_dir} not found. Exiting."
    exit 1
fi

# Retrieves the default Java version in the format "JAVA<VERSION>". For example,
# "JAVA8", "JAVA11".
get_java_version() {
  # Get the Java version and store it in a variable
  java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')

  # Extract the major version number
  if [[ "$java_version" == 1.* ]]; then
    major_version=$(echo "$java_version" | cut -d. -f2)
  else
    major_version=$(echo "$java_version" | cut -d. -f1)
  fi

  # Format the result as "JAVAX"
  java_format="JAVA$major_version"

  # Return the formatted result
  echo "$java_format"
}

# Try to compile a commit and write the compilation result to stdout.
# Arguments:
# 1) Project name
# 2) Project VCS URL
# 3) Commit hash
compile(){
  local project_name="$1"
  local vcs_url="$2"
  local commit_hash="$3"

  local short_commit_fix="${commit_hash:0:6}"
  local repository="${clone_dir}/${project_name}_${short_commit_fix}"

  # TODO: Find a way to speed this up.
  # IDEA: Use a local clone of the repository and copy clone.
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
    src/bash/main/compile-project.sh "${repository}" > "${repository}/compile.log" 2>&1
    ret_code=$?
    untangling_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "$java_version")"
  fi

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%s,%s,%s,%.0fs\n" "${project_name}" "${short_commit_fix}" "${untangling_status_string}" "${ELAPSED}"
}

export -f get_java_version
export -f compile

java_version=$(get_java_version)
export java_version

printf "%s,%s,%s,%s\n" "project_name" "commit_hash" "compilation_status" "elapsed_time"
tail -n+2 "$commits_file" | parallel --colsep "," compile {}
