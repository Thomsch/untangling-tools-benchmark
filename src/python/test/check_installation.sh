#!/bin/bash

# Check for requirements:
# - Python 3.8.15 is the version used and on the PATH.
# - JAVA 8 is the default version on the PATH, but not used to run SmartCommit and Flexeme.
# - JAVA 11 is installed, but not on the PATH.
# Check for PyGraphviz and GNU coreutiles.

set -o errexit
set -o nounset
set -o allexport
source .env
set +o allexport

# Check Python is 3.8.15 for Flexeme.
python_version=$(python --version 2>&1 | awk '{print $2}')
if [[ "$python_version" != "3.8.15" ]]; then
    echo "Error: Required Python version is 3.8.15 but found $python_version"
    exit 1
fi

# Check Java is 1.8 for Defects4j. 
java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c1-3)
if [ "$java_version" != "1.8" ] ; then
    echo "Use Java 8, not ${java_version}."
    exit 1
fi

# Check JAVA 11 is installed and on PATH. Defects4J will use whatever is on JAVA_HOME.
if [[ -z "${JAVA11_HOME}" ]]; then
  echo 'JAVA11_HOME environment variable is not set.'
  echo 'Please set it to the path of a Java 11 java.'
  exit 1
fi

# Check for each program in the system's PATH 
for package in defects4j flexeme date cpanm ; do
    if ! command -v "$package" >/dev/null 2>&1; then
        echo "Error: Required package '$package' is not installed."
        exit 1
    fi
done
echo 'The tool dependencies are satisfied.'

