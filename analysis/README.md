# Data Analysis

This folder contains the scripts used to analyze the results of the decomposition. The folder is organized as follows:
- `data/` contains the raw data of the decomposition use for data exploration.
- `data/smartcommit-reported.csv` contains the data of the decomposition reported in the SmartCommit paper.
- `manual/` contains files related to the manual analysis.
- `paper/` contains helper scripts to generate the results for the paper.
- `generate-paper.sh` is a script to generate all the results for the paper. See section [Paper](#paper).
- The remaining files are scripts and notebook to explore data and generate results.

## Paper
Use `generate-paper.sh` to generate the analysis results of the decomposition and update the tables and figures in the paper.
The script takes as input a clone of the paper repository (https://gitlab.cs.washington.edu/tschweiz/code-changes-benchmark).
