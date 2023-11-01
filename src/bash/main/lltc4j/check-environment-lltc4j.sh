#!/bin/sh

# This script optionally sets, then checks, environment variables.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
env_file="${SCRIPT_DIR}/../../../../.env"

if [ -f "$env_file" ] ; then
  set -o allexport

  # shellcheck source=.env
  . "$env_file"
  set +o allexport
fi

if [ -z "${JAVA11_HOME}" ]; then
  echo 'Set JAVA11_HOME_HOME environment variable to the Java 11 installation.'
  exit 1
fi

if [ ! -d "${JAVA11_HOME}" ]; then
  echo "JAVA11_HOME environment variable is not set to an existing directory: $JAVA11_HOME"
  exit 1
fi
