# .DEFAULT_GOAL := out/decomposition.csv

check: check-scripts check-python

check-scripts:
    # Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh scripts/*.sh)

PYTHON_FILES=$(wildcard src/*.py)
python-style:
	black ${PYTHON_FILES}
	pylint -f parseable --disable=W,invalid-name ${PYTHON_FILES}


# out/commits.csv:
# 	./scripts/active_bugs.sh > out/commits.csv
#
# out/decomposition.csv:
# 	./evaluate_all.sh

clean: 
	rm -rf ./tmp/

.PHONY: clean
