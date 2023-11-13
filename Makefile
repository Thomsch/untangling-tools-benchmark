# .DEFAULT_GOAL := out/decomposition.csv

check: shell-script-style check-python-format check-python-style python-test shell-test

SH_SCRIPTS   = $(shell grep -r -l '^\#! \?\(/bin/\|/usr/bin/env \)sh'   * | grep -v /.git/ | grep -v '~$$' | grep -v '\.tar$$' | grep -v addrfilter | grep -v cronic-orig | grep -v gradlew | grep -v mail-stackoverflow.sh)
BASH_SCRIPTS = $(shell grep -r -l '^\#! \?\(/bin/\|/usr/bin/env \)bash' * | grep -v /.git/ | grep -v '~$$' | grep -v '\.tar$$' | grep -v addrfilter | grep -v cronic-orig | grep -v gradlew | grep -v mail-stackoverflow.sh)

MAKEFILE_DIR:=$(strip $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

shell-script-style:
	shellcheck -x -P SCRIPTDIR --format=gcc ${SH_SCRIPTS} ${BASH_SCRIPTS}
	checkbashisms ${SH_SCRIPTS} /dev/null

showvars:
	@echo "SH_SCRIPTS=${SH_SCRIPTS}"
	@echo "BASH_SCRIPTS=${BASH_SCRIPTS}"

PYTHON_FILES=$(wildcard *.py analysis/*.py src/python/main/*.py src/python/test/*.py)
check-python-style:
	flake8 --color never --ignore E501,W503 ${PYTHON_FILES}
	pylint -f parseable ${PYTHON_FILES}

check-python-format:
	black --check ${PYTHON_FILES}

format-python:
	black ${PYTHON_FILES}

python-test:
	PYTHONPATH="${MAKEFILE_DIR}/src/python/main" pytest src/python/test

shell-test:
	bats "${MAKEFILE_DIR}/src/bash/test"

.PHONY: clean
clean: 
	rm -rf ./tmp/

TAGS: tags
tags:
	etags $(shell find . -name '*.py') $(shell find . -name '*.sh')
