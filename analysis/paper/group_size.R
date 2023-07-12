#!/usr/bin/env Rscript

library(tidyverse)
library(xtable)

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=2) {
  stop("Please provide an input file and output file.n", call.=FALSE)
}
inputFile = args[1]
outputFile = args[2]

data <- read.csv(inputFile)
data$BugId <- as_factor(data$BugId)

groupSize <- data %>% group_by(Project, BugId, Treatment, Group) %>% summarise(n = n())
summary <- groupSize %>% group_by(Treatment) %>% summarise("Min."=min(n), "Max."=max(n), "Median"=median(n), "Std. Dev."=sd(n))

summary.table <- xtable(summary)

print(summary.table, only.contents = TRUE, booktabs = TRUE, timestamp	= NULL, comment = FALSE, include.rownames = FALSE, file=outputFile)
