# .DEFAULT_GOAL := out/decomposition.csv

check: check-scripts check-python-format check-python-style python-test

check-scripts:
# Fail if any of these files have warnings
# Note: as of 2023-07-11, the GitHub "ubuntu-latest" image contains shellcheck 0.8.0-2, which is not the latest version.
# See https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2204-Readme.md#installed-apt-packages .
	shellcheck $(wildcard ./*.sh src/bash/main/*.sh)

PYTHON_FILES=$(wildcard *.py analysis/*.py src/python/main/*.py src/python/test/*.py)
check-python-style:
	flake8 --color never --ignore E501,W503 ${PYTHON_FILES}
	pylint -f parseable ${PYTHON_FILES}

check-python-format:
	black --check ${PYTHON_FILES}

format-python:
	black ${PYTHON_FILES}

python-test:
	PYTHONPATH="${GITHUB_WORKSPACE}/src/python/main" pytest src/python/test

clean: 
	rm -rf ./tmp/

.PHONY: clean
