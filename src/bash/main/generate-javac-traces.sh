#!/bin/bash
# Run javac on a list of commits from different projects with the default system Java version.
# The compilation generates javac traces containing the sourcepath and classpath used to compile the project.
#
# Arguments:
# - $1: The CSV file containing the commits to untangle with header:
#       vcs_url,commit_hash,parent_hash
# - $2: Directory to store project clones.
#
# The results are written to stdout in CSV format with the following columns:
# - Name of the project
# - Commit hash (abbreviated to 6 characters)
# - Compilation status. Shows the Java version, or the status tag "FAIL" or "COMMIT_NOT_FOUND".
# - Time elapsed. In seconds, rounded to the nearest integer.
#
# Each version of the project is cloned in a directory named after the project
# commit hash. The execution log 'compile.log' is written at the root of each
# clone.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 2 ] ; then
    echo "usage: $0 <commits_file> <clone_dir>"
    exit 1
fi

export commits_file="$1"
export clone_dir="$2"

if ! [ -f "$commits_file" ]; then
    echo "$0: commit file ${commits_file} not found. Exiting."
    exit 1
fi

if ! [ -d "$clone_dir" ]; then
    echo "$0: directory ${clone_dir} not found. Exiting."
    exit 1
fi

get_project_name_from_url() {
  local url="$1"
  local filename="${url##*/}"
  local basename="${filename%%.*}"
  echo "$basename"
}

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

  echo "JAVA$major_version"
}

# Try to compile a commit and write the compilation result to stdout as a 4-column CSV row.
# Arguments:
# 1) Project VCS URL
# 2) Commit hash
compile() {
  local vcs_url="$1"
  local commit_hash="$2"

  local project_name
  project_name=$(get_project_name_from_url "$vcs_url")
  local short_commit_hash="${commit_hash:0:6}"

  local repository="${clone_dir}/${project_name}_${short_commit_hash}"
  echo "$repository"

  START="$(date +%s.%N)"

  # TODO: Do not clone the repository for each commit. Clone it once per project and then copy the directory for each commit.
  # Cloning the repository for each commit is slow and might cause issues with GitHub rate limits or the internet provider.
  git clone -q "$vcs_url" "$repository"
  cd "$repository"
  git checkout -q "$commit_hash"
  checkout_ret_code=$?
  cd - >/dev/null
  if [ $checkout_ret_code -ne 0 ]; then
    untangling_status_string="COMMIT_NOT_FOUND"
  fi

  if [ -z "$untangling_status_string" ]; then
    export ERR_IF_NO_BUILDFILE=1 # Exit with an error if no buildfile is found.
    src/bash/main/compile-project.sh "${repository}" > "${repository}/compile.log" 2>&1
    compile_exit_code=$?

    if [ "$compile_exit_code" -eq 0 ]; then
      untangling_status_string="$java_version"
    elif [ "$compile_exit_code" -eq 222 ]; then
      untangling_status_string="BUILD_FILE_NOT_FOUND"
    else
      untangling_status_string="FAIL"
    fi
  fi

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%s,%s,%s,%.0fs\n" "${project_name}" "${short_commit_hash}" "${untangling_status_string}" "${ELAPSED}"
}

export -f get_project_name_from_url
export -f compile

java_version=$(get_java_version)
export java_version

echo "java_version: $java_version" >&2

printf "%s,%s,%s,%s\n" "project_name" "commit_hash" "compilation_status" "elapsed_time"
# Reads the commits file, ignoring the CSV header, and compiles each commit in parallel.
tail -n+2 "$commits_file" | parallel --colsep "," compile {}
