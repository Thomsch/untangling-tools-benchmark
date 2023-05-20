#!/bin/bash
# Collection of utilities that interface with Defects4J.

# Retrieves the buggy and fixed revision IDs for a given project and bug ID.
# - $1: D4J Project name
# - $2: D4J Bug id
# Returns the buggy and fixed revision IDs in the format:
#   <revision_id_buggy> <revision_id_fixed>
retrieve_revision_ids () {
  if [[ $# -ne 2 ]] ; then
      echo 'usage: retrieve_revision_ids <D4J Project> <D4J Bug id>'
      echo 'example: retrieve_revision_ids Lang 1'
      exit 1
    fi

  local project="$1"
  local bug_id="$2"

  # Check if the DEFECTS4J_HOME environment variable is set
  if [[ -z "${DEFECTS4J_HOME}" ]]; then
    echo 'DEFECTS4J_HOME environment variable not set.' 1>&2
    echo 'Please set it to the path of your Defects4J installation.' 1>&2
    return 1
  fi

  # Retrieve the path to the active-bugs.csv file
  csv_file="${DEFECTS4J_HOME}/framework/projects/${project}/active-bugs.csv"

  # Find the line with the matching bug ID
  local line
  line=$(grep "^$bug_id," "$csv_file")

  if [[ -z $line ]]; then
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