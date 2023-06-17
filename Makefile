# .DEFAULT_GOAL := out/decomposition.csv

check: check-scripts python-test

check-scripts:
    # Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh scripts/*.sh)

# black's formatting is akward for some lines, I'm removing it from `check` until I can tweak the config.
PYTHON_FILES=$(wildcard *.py analysis/*.py src/*.py test/*.py)
python-style:
	black ${PYTHON_FILES}
	pylint -f parseable --disable=W,invalid-name ${PYTHON_FILES}

python-test:
	pytest test
clean: 
	rm -rf ./tmp/

.PHONY: clean
