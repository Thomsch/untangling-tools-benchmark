#!/bin/bash

# Check for requirements:
# - Python 3.8.15 is the version used and on the PATH.
# - JAVA 8 is the default version on the PATH, but not used.
# - JAVA 11 is installed, but not on the PATH
# Check for PyGraphviz and GNU coreutiles

set -o errexit
set -o nounset
set -o allexport
# shellcheck source=/dev/null
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
if [[ $(echo "$java_version != 1.8" | bc) == 1 ]] ; then
    echo "Unsupported Java Version: ${java_version}. Please use Java 8."
    exit 1
fi

# Check JAVA 11 is installed and on PATH. Defects4J will use whatever is on JAVA_HOME.
if [[ -z "${JAVA_11}" ]]; then
  echo 'JAVA_11 environment variable is not set.'
  echo 'Please set it to the path of a Java 11 java.'
  exit 1
fi

# Check for each program in the system's PATH 
required_packages=("defects4j" "flexeme" "date" "cpanm")

for package in "${required_packages[@]}"; do
    if ! command -v "$package" >/dev/null 2>&1; then
        echo "Error: Required package '$package' is not installed."
        exit 1
    fi
done
echo 'All required packages, installations and dependencies are satisfied. The tool is ready.'

