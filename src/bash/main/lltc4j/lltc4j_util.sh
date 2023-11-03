# Utility functions used by the lltc4j scripts.

# Returns the project_name name from an URL.
get_project_name_from_url() {
  local url="$1"
  local filename="${url##*/}"
  local basename="${filename%%.*}"
  echo "$basename"
}

# Format progress messages.
# Arguments:
# - $1: The message to print.
# - $2: The status of the message. e.g., OK, FAIL, etc.
print_progress() {
  echo "$1 .............................................. $2"
}

# Print the progress of the untangling process.
# Arguments:
# - $1: The name of the untangling tool.
# - $2: The status of the untangling process. e.g., OK, FAIL, etc.
print_untangling_progress() {
  print_progress "Untangling with $1" "$2"
}

# Print the progress of the parsing process.
# Arguments:
# - $1: The name of the untangling tool.
# - $2: The status of the parsing process. e.g., OK, FAIL, etc.
print_parsing_progress() {
  print_progress "Parsing $1 results" "$2"
}

export -f get_project_name_from_url
export -f print_progress
export -f print_untangling_progress
export -f print_parsing_progress