#!/bin/sh

## This script comes from
## https://github.com/plume-lib/manage-git-branches/blob/main/compile-project.

# Compile the project that contains the current or given directory.
#
# Supports Gradle, Maven, and Make projects.  If no buildfile is found
# at the top level, searches at (only) the next level down.
#
# The exit status is failure if any build fails.  If no buildfile is
# found and ERR_IF_NO_BUILDFILE is set to a non-empty value, then the
# exit status is failure.
#
# Usage:
#   compile-project [<directory>]
#
# If variable GRADLE_ASSEMBLE_FLAGS is defined, it is passed to `gradle assemble`.
# If variable MVN_COMPILE_FLAGS is defined, it is passed to `mvn compile`.
# If variable MAKE_FLAGS is defined, it is passed to `make`.
# If variable ERR_IF_NO_BUILDFILE is non-empty, the script fails if no buildfile is found.
#
# This command does not need to be run in the top-level directory of the project;
# it will discover the top-level directory on its own and run the command there.

# TODO: Handle other build systems too, such as Ant.
# TODO: Have a list of per-directory or per-repository commands, to override the default.

if [ "$#" -eq 0 ]; then
  # $toplevel does not have a trailing "/" character
  toplevel="$(git rev-parse --show-toplevel 2>&1)"
elif [ "$#" -eq 1 ]; then
  toplevel="$1"
elif [ "$#" -ne 1 ]; then
  echo "Usage: $(basename "$0") [<directory>]" >&2
  exit 1
fi

echo "Running compile-project in $toplevel from $(pwd)" >&2

case $toplevel in
    "fatal: not a git repository"*) toplevel=$(pwd) ;;
esac

# Returns a status code indicating success or failure, or 222 if no buildfile was found.
# Saves the results of dljc in a folder called dljc-logs in the cloned repository.
compile_in_directory() {
  if [ "$#" -ne 1 ] ; then
    echo "compile_in_directory got $# arguments: $*"
    exit 1
  fi
  dir="$1"

  if [ -f "$dir/gradlew" ]; then
    echo "Build system detected: Gradle Wrapper" >&2
    # shellcheck disable=SC2086 # Word splitting is desirable here.
    "$dir/gradlew" --project-dir "$dir" assemble -q ${GRADLE_ASSEMBLE_FLAGS} < /dev/null
    return $?
  elif [ -f "$dir/build.gradle" ]; then
    echo "Build system detected: Gradle" >&2
    # shellcheck disable=SC2086 # Word splitting is desirable here.
    dljc -t print -o "$dir/dljc-logs" -- gradle --project-dir "$dir" assemble -q ${GRADLE_ASSEMBLE_FLAGS} < /dev/null
    return $?
  elif [ -f "$dir/mvnw" ]; then
    echo "Build system detected: Maven Wrapper" >&2
    # shellcheck disable=SC2086 # Word splitting is desirable here.
    (cd "$dir" && ./mvnw -q compile ${MVN_COMPILE_FLAGS})
    return $?
  elif [ -f "$dir/pom.xml" ]; then
    echo "Build system detected: Maven" >&2
    # shellcheck disable=SC2086 # Word splitting is desirable here.
    (cd "$dir" &&
    dljc -t print -o "$dir/dljc-logs" -- mvn -q compile ${MVN_COMPILE_FLAGS})
    return $?
  elif [ -f "$dir/Makefile" ]; then
    echo "Build system detected: Make" >&2
    # shellcheck disable=SC2086 # Word splitting is desirable here.
    (cd "$dir" && make ${MAKE_FLAGS})
    return $?
  else
    # No buildfile was found.
    return 222
  fi
}

compile_in_directory "$toplevel"
result=$?

if [ "$result" != 222 ] ; then
  # A buildfile was found, exit with the exit code of the compilation step.
  exit $result
else
  # Call compile_in_directory in subdirectories.
  buildfile_found=0
  for subdir in "$toplevel"/*/ ; do
    compile_in_directory "$subdir"
    result=$?
    if [ "$result" = 222 ] ; then
      continue
    fi
    buildfile_found=1
    if [ ! $result ] ; then
      exit $result
    fi
  done
  if [ "$buildfile_found" = 0 ] && [ -n "$ERR_IF_NO_BUILDFILE" ]; then
    echo "compile-project did nothing in $(pwd)"
    exit 1
  fi
fi
