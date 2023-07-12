#!/bin/bash
# Collection of utilities that interface with Defects4J.

# Generates the unified diff in the same format for Git and Svn repositories for a defects4j commit.
d4j_diff () {
    if [ $# -ne 5 ] ; then
      echo 'usage: d4j_diff <D4J Project> <D4J Bug id> <Revision Before> <Revision After> <Project Repository>'
      echo 'example: d4j_diff Lang 1 abc def path/to/Lang_1/'
      return 1
    fi

    local PROJECT="$1"
    local VID="$2"
    local REVISION_BUGGY="$3"
    local REVISION_FIXED="$4"
    local REPO_DIR="$5"

    vcs="$(defects4j query -p "$PROJECT" -q "project.vcs" | awk -v vid="$VID" -F',' '{ if ($1 == vid) { print $2 } }')"

    if [[ $vcs == "Vcs::Git" ]] ; then
        git --git-dir="${REPO_DIR}/.git" diff --ignore-all-space -U0 "$REVISION_BUGGY" "$REVISION_FIXED"
    elif [[ $vcs == "Vcs::Svn" ]]; then
        svn diff -c --old"${REVISION_BUGGY}" --new="${REVISION_FIXED}" "${REPO_DIR}"  --diff-cmd diff -x -w "-U 0"
    else
        echo "Error: VCS ${vcs} not supported."
        return 1
    fi
}

# Retrieves the buggy and fixed revision IDs in the underlying version control
# system for a given Defects4J project and bug ID.
# - $1: D4J Project name
# - $2: D4J Bug id
# Returns the buggy and fixed revision IDs in the format:
#   <revision_id_buggy> <revision_id_fixed>
retrieve_revision_ids () {
  if [ $# -ne 2 ] ; then
      echo 'usage: retrieve_revision_ids <D4J Project> <D4J Bug id>'
      echo 'example: retrieve_revision_ids Lang 1'
      return 1
    fi

  local project="$1"
  local bug_id="$2"

  # Check if the DEFECTS4J_HOME environment variable is set
  if [ -z "${DEFECTS4J_HOME}" ]; then
    echo 'DEFECTS4J_HOME environment variable is not set.' 1>&2
    echo 'Please set it to the path of your Defects4J installation.' 1>&2
    return 1
  fi

  # Retrieve the path to the active-bugs.csv file
  csv_file="${DEFECTS4J_HOME}/framework/projects/${project}/active-bugs.csv"

  # Find the line with the matching bug ID
  local line
  line=$(grep "^$bug_id," "$csv_file")

  if [ -z $line ]; then
    echo "Bug ID $bug_id not found." 1>&2
    return 1
  fi

  # Parse the line to retrieve revision.id.buggy and revision.id.fixed
  IFS=',' read -ra fields <<< "$line"
  local revision_id_buggy="${fields[1]}"
  local revision_id_fixed="${fields[2]}"

  # Return the results
  echo "$revision_id_buggy $revision_id_fixed"
}
