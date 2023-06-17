#!/bin/bash

# Check if the local machine satisfy requirements:
# - Python 3.8.15 is the version used and on the PATh.
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

# Check for each package in both the system's PATH and the additional directories.
required_packages=("defects4j" "flexeme" "graphviz" "coreutils")
additional_directories=("/opt/homebrew/opt")  # Add additional directories here

for package in "${required_packages[@]}"; do
    found=false

    # Check in system's PATH
    if command -v "$package" >/dev/null 2>&1; then
        found=true
    fi

    # Check in additional directories
    for dir in "${additional_directories[@]}"; do
        if [ -x "$dir/$package" ]; then
            found=true
            break
        fi
    done

    if ! $found; then
        echo "Error: Required package '$package' is not installed."
        exit 1
    fi
done
echo 'All required packages, installations and dependencies are satisfied. The tool is ready.'

