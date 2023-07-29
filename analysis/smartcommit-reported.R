#!/usr/bin/env Rscript
#
# Computes the mean and median accuracy value for the experiment results of
# the SmartCommit paper.

library(tidyverse)

data <- read.csv("analysis/data/smartcommit-reported.csv")
data

data %>% group_by(method) %>% summarise("Mean"=mean(accuracy), "Median"=median(accuracy))
