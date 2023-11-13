# Utility functions used by the LLTC4J scripts.

# Returns the project name from a git repository's URL.
#
# Arguments:
# - $1: The URL of the git repository.
get_project_name_from_url() {
  local url="$1"
  local filename="${url##*/}"
  local basename="${filename%%.*}"
  echo "$basename"
}

# Returns the shortened commit hash from a commit hash. The shortened commit
# hash is the first 6 characters of the commit hash, like git does.
#
# Arguments:
# - $1: The commit hash.
get_short_commit_hash() {
  local commit_hash="$1"
  echo "${commit_hash:0:6}"
}

# Returns a unique identifier for a commit. The identifier is composed
# of the project name and the commit hash. i.e., <project name>_<commit hash>.
#
# The identifier is guaranteed to be unique for commits in the LLTC4J dataset.
# Other datasets containing duplicate repositories owned by different users or
# organizations may have duplicate identifiers. In this case, we recommend to
# include the user or organization name in the identifier.
#
# Arguments:
# - $1: The project name.
# - $2: The commit hash.
get_commit_identifier() {
  local project_name="$1"
  local commit_hash="$2"
  echo "${project_name}_$(get_short_commit_hash "$commit_hash")"
}

export -f get_project_name_from_url
export -f get_short_commit_hash
export -f get_commit_identifier
