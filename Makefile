.DEFAULT_GOAL := out/decomposition.csv

check-scripts:
    # Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh)

out/commits.csv:
	./scripts/active_bugs.sh > out/commits.csv

out/decomposition.csv:
	./evaluate_all.sh

clean: 
	rm -rf ./tmp/

.PHONY: clean