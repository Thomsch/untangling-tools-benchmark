# Utility functions used by the lltc4j scripts.

# Returns the project_name name from an URL.
get_project_name_from_url() {
  local url="$1"
  local filename="${url##*/}"
  local basename="${filename%%.*}"
  echo "$basename"
}

# Untangles a commit from the LLTC4J dataset using Flexeme.
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_flexeme(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"

  local log_file
  log_file="${logs_dir}/${project_name}_${short_commit_hash}_flexeme.log"

  START="$(date +%s.%N)"

  # If the ground truth is missing, skip this commit.
  if ! [ -f "${results_dir}/evaluation/${project_name}_${short_commit_hash}/truth.csv" ]; then
    untangling_status_string="MISSING_GROUND_TRUTH"
  fi

  javac_traces_file="${javac_traces_dir}/${project_name}_${short_commit_hash}/dljc-logs/javac.json"

  if ! [ -f "$javac_traces_file" ]; then
    untangling_status_string="MISSING_JAVAC_TRACES"
    sourcepath=""
    classpath=""
  else
    # Retrieve the sourcepath and classpath from the javac traces.
    sourcepath=$(python3 "$SCRIPT_DIR/../../../python/main/retrieve_javac_compilation_parameter.py" -p sourcepath -j "$javac_traces_file")
    classpath=$(python3 "$SCRIPT_DIR/../../../python/main/retrieve_javac_compilation_parameter.py" -p classpath -j "$javac_traces_file")
  fi

  # If the untangling status is still empty, untangle the commit.
  if [ -z "$untangling_status_string" ]; then
    ./src/bash/main/lltc4j/untangle_flexeme_commit.sh "$vcs_url" "$commit_hash" "$results_dir" "$sourcepath" "$classpath" > "${log_file}" 2>&1
    ret_code=$?
    if [ $ret_code -eq 0 ]; then
      untangling_status_string="OK"
    elif [ $ret_code -eq 5 ]; then
      untangling_status_string="UNTANGLING_FAIL"
    elif [ $ret_code -eq 6 ]; then
      untangling_status_string="PARSING_FAIL"
    else
      untangling_status_string="FAIL"
    fi
  fi
  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%-20s %-20s (time: %.0fs) [%s]\n" "${project_name}_${short_commit_hash}" "${untangling_status_string}" "${ELAPSED}" "${log_file}"
}

# Untangles a commit from the LLTC4J dataset using SmartCommit and Flexeme.
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_smartcommit(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"

  START="$(date +%s.%N)"   # Record start time for bug decomposition
  ./src/bash/main/lltc4j/untangle_lltc4j_commit.sh "$vcs_url" "$commit_hash" "$results_dir" > "${logs_dir}/${project_name}_${short_commit_hash}_untangle.log" 2>&1
  ret_code=$?
  untangling_status_string="$([ $ret_code -ne 0 ] && echo "FAIL" || echo "OK")"
  END="$(date +%s.%N)"
  # Must use `bc` because the computation is on floating-point numbers.
  ELAPSED="$(echo "$END - $START" | bc)"
  printf "%-20s %s (time: %.0fs)\n" "${project_name}_${short_commit_hash}" "${untangling_status_string}" "${ELAPSED}"
}

# Untangles a commit from the LLTC4J dataset using the file-based approach.
# Arguments:
# - $1: The URL of the git repository for the project.
# - $2: The commit hash to untangle.
untangle_file(){
  local vcs_url="$1" # The URL of the git repository for the project.
  local commit_hash="$2" # The commit hash to untangle.
  local project_name
  project_name="$(get_project_name_from_url "$vcs_url")"
  short_commit_hash="${commit_hash:0:6}"
  commit_identifier="${project_name}_${short_commit_hash}"

  local log_file="${logs_dir}/${commit_identifier}_file_untangling.log"
  local result_dir="${results_dir}/evaluation/${commit_identifier}" # Directory where the parsed untangling results are stored.
  local ground_truth_file="${result_dir}/truth.csv"
  local file_untangling_out="${result_dir}/file_untangling.csv"

  mkdir -p "$result_dir"

  START="$(date +%s.%N)"

  # If the ground truth is missing, skip this commit.
  if ! [ -f "$ground_truth_file" ]; then
    untangling_status_string="MISSING_GROUND_TRUTH"
    echo "Missing ground truth for ${project_name}_${short_commit_hash}. Skipping." >> "$log_file"
  elif [ -f "$file_untangling_out" ]; then
    echo 'Untangling with file-based approach .................................. CACHED' >> "$log_file"
    untangling_status_string="CACHED"
  else
    echo 'Untangling with file-based approach ..................................' >> "$log_file"
    if python3 src/python/main/filename_untangling.py "${ground_truth_file}" "${file_untangling_out}" >> "$log_file" 2>&1 ;
    then
        untangling_status_string="OK"
    else
        untangling_status_string="FAIL"
    fi
    echo "Untangling with file-based approach .................................. ${untangling_status_string}" >> "$log_file"
  fi

  END="$(date +%s.%N)"
  ELAPSED="$(echo "$END - $START" | bc)" # Must use `bc` because the computation is on floating-point numbers.
  printf "%-20s %-20s (time: %.0fs) [%s]\n" "${commit_identifier}" "${untangling_status_string}" "${ELAPSED}" "${log_file}"
}

export -f get_project_name_from_url
export -f untangle_flexeme
export -f untangle_smartcommit
export -f untangle_file
