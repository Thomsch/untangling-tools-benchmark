# .DEFAULT_GOAL := out/decomposition.csv

check: check-scripts check-python-format check-python-style python-test

check-scripts:
# Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh scripts/*.sh test/*.sh)

PYTHON_FILES=$(wildcard *.py analysis/*.py src/*.py test/*.py)
check-python-style:
	flake8 --color never --ignore E501,W503 ${PYTHON_FILES}
	pylint -f parseable --disable=W,invalid-name,line-too-long ${PYTHON_FILES} --init-hook="import sys; sys.path.append('.venv/lib/python3.8/site-packages')"

check-python-format:
	black ${PYTHON_FILES}

format-python:
	black ${PYTHON_FILES}

python-test:
	pytest test

clean: 
	rm -rf ./tmp/

.PHONY: clean
