# .DEFAULT_GOAL := out/decomposition.csv

# TODO: Add "check-python-style" when it passes.
check: check-scripts check-python-format python-test

check-scripts:
    # Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh scripts/*.sh test/*.sh)

# black's formatting is akward for some lines, I'm removing it from `check` until I can tweak the config.
PYTHON_FILES=$(wildcard *.py analysis/*.py src/*.py test/*.py)
check-python-style:
	pylint -f parseable --disable=W,invalid-name ${PYTHON_FILES}

check-python-format:
	black --check ${PYTHON_FILES}

format-python:
	black ${PYTHON_FILES}

python-test:
	pytest test
clean: 
	rm -rf ./tmp/

.PHONY: clean
