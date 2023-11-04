#!/bin/sh

# This script optionally sets, then checks, the environment variables.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
env_file="${SCRIPT_DIR}/../../../../.env"

if [ -f "$env_file" ] ; then
  set -o allexport
  # shellcheck source=/dev/null
  . "$env_file"
  set +o allexport
fi

if [ -z "${JAVA11_HOME}" ]; then
  echo 'Set the JAVA11_HOME_HOME environment variable to the Java 11 installation.'
  exit 1
fi

if [ ! -d "${JAVA11_HOME}" ]; then
  echo "The JAVA11_HOME environment variable is not an existing directory: $JAVA11_HOME"
  exit 1
fi
