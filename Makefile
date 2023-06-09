# .DEFAULT_GOAL := out/decomposition.csv

check: check-scripts python-test

check-scripts:
# Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh scripts/*.sh)

# black's formatting is akward for some lines, I'm removing it from `check` until I can tweak the config.
## TODO: Even if you don't like black's formatting in some places, live with it.  It's better for your code to be consistent than to manually adjust it to your personal taste.
PYTHON_FILES=$(wildcard src/*.py)
python-style:
	black ${PYTHON_FILES}
	pylint -f parseable --disable=W,invalid-name ${PYTHON_FILES}

python-test:
	pytest test

clean: 
	rm -rf ./tmp/

.PHONY: clean
