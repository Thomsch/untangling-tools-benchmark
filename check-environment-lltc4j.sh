#!/bin/sh

# This script optionally sets, then checks, environment variables.

if [ -f .env ] ; then
  set -o allexport
  # shellcheck disable=SC1091 # File might not exist.
  . .env
  set +o allexport
fi

if [ -z "${DEFECTS4J_HOME}" ]; then
  echo 'Set DEFECTS4J_HOME environment variable to the Defects4J repository.'
  exit 1
fi

if [ ! -d "${DEFECTS4J_HOME}" ]; then
  echo "DEFECTS4J_HOME environment variable is not set to an existing directory: $DEFECTS4J_HOME"
  exit 1
fi

if [ -z "${JAVA11_HOME}" ]; then
  echo 'Set JAVA11_HOME_HOME environment variable to the Java 11 installation.'
  exit 1
fi

if [ ! -d "${JAVA11_HOME}" ]; then
  echo "JAVA11_HOME environment variable is not set to an existing directory: $JAVA11_HOME"
  exit 1
fi
