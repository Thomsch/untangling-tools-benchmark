#!/bin/sh

# Compile the project that contains the current directory.
# Usage:
#   compile-project
#
# Supports Gradle, Maven, and Make projects.
# If variable GRADLE_ASSEMBLE_FLAGS is defined, it is passed to `gradle assemble`.
# If variable MVN_COMPILE_FLAGS is defined, it is passed to `mvn compile`.
# If variable MAKE_FLAGS is defined, it is passed to `make`.
#
# This command does not need to be run in the top-level directory of the project;
# it will discover the top-level directory on its own and run the command there.

# TODO: Handle other build systems too, such as Ant.
# TODO: Have a list of per-directory or per-repository commands, to override the default.

if [ "$#" -ne 1 ]; then
  echo "Usage: $(basename "$0")" >&2
  exit 1
fi

echo "Running compile-project in $1 from $(pwd)"

# shellcheck disable=SC2034 # Variable not used yet.
toplevel="$1"

if [ -f "$toplevel/gradlew" ]; then
  # shellcheck disable=SC2086 # Word splitting is desirable here.
  "$toplevel/gradlew" --project-dir "$toplevel" assemble -q ${GRADLE_ASSEMBLE_FLAGS}
elif [ -f "$toplevel/build.gradle" ]; then
  # shellcheck disable=SC2086 # Word splitting is desirable here.
  gradle --project-dir "$toplevel" assemble -q ${GRADLE_ASSEMBLE_FLAGS}
elif [ -f "$toplevel/mvnw" ]; then
  # shellcheck disable=SC2086 # Word splitting is desirable here.
  (cd "$toplevel" && ./mvnw -q compile ${MVN_COMPILE_FLAGS})
elif [ -f "$toplevel/pom.xml" ]; then
  # shellcheck disable=SC2086 # Word splitting is desirable here.
  (cd "$toplevel" && mvn -q compile ${MVN_COMPILE_FLAGS})
elif [ -f "$toplevel/Makefile" ]; then
  # shellcheck disable=SC2086 # Word splitting is desirable here.
  (cd "$toplevel" && make ${MAKE_FLAGS})
else
  echo "compile-project did nothing in $(pwd)"
  exit 1
fi
