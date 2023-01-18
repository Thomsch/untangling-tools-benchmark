check-scripts:
    # Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh)

out/commits.csv:
	./scripts/active_bugs.sh > out/commits.csv

all: out/commits.csv

.PHONY: all