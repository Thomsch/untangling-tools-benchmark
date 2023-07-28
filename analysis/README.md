# Data Analysis

This folder contains the scripts used to analyze the results of the decomposition. The folder is organized as follows:
- `data/` contains the raw data of the decomposition use for data exploration.
- `data/smartcommit-reported.csv` contains the data of the decomposition reported in the SmartCommit paper.
- `manual/` contains files related to the manual analysis.
- `paper/` contains scripts to generate the results for the paper.
- `generate-paper.sh` is a script to generate the results for the paper. See section [Paper](#paper).
- The remaining files are scripts and notebook to explore data and generate results.

## Paper
Use `./analysis/generate-paper.sh` to generate the analysis results of the decomposition and update the tables and figures in the paper.
The script expects that the paper repository (https://gitlab.cs.washington.edu/tschweiz/code-changes-benchmark) is checkout out on the disk.