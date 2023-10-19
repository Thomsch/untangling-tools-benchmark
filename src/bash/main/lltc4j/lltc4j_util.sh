# Utility functions used by the lltc4j scripts.

# Returns the project_name name from an URL.
get_project_name_from_url() {
  local url="$1"
  local filename="${url##*/}"
  local basename="${filename%%.*}"
  echo "$basename"
}

export -f get_project_name_from_url