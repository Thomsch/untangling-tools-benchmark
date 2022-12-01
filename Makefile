check-scripts:
    # Fail if any of these files have warnings
	shellcheck $(wildcard ./*.sh)