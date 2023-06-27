# .DEFAULT_GOAL := out/decomposition.csv

# TODO: Change "check-some-python-style" to "check-python-style" when it passes.
check: check-scripts check-python-format check-some-python-style python-test

check-scripts:
# Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh scripts/*.sh test/*.sh)

PYTHON_FILES=$(wildcard *.py analysis/*.py src/*.py test/*.py)
check-python-style:
	flake8 --color never --ignore E501,W503 ${PYTHON_FILES}
	pylint -f parseable --disable=W,invalid-name ${PYTHON_FILES}

check-some-python-style:
	flake8 --color never --ignore E501,W503 ${PYTHON_FILES}
	pylint -f parseable --disable=W,invalid-name conftest.py src/__init__.py

check-python-format:
	black --check ${PYTHON_FILES}

format-python:
	black ${PYTHON_FILES}

python-test:
	pytest test

clean: 
	rm -rf ./tmp/

.PHONY: clean
