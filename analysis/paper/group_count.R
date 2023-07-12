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

groupCount <- data %>% group_by(Project, BugId, Treatment) %>% summarise(GroupCount = n_distinct(Group))
summary <- groupCount %>% group_by(Treatment) %>% summarise("Min."=min(GroupCount), "Max."=max(GroupCount), "Median."=median(GroupCount), "Std. Dev."=sd(GroupCount))
summary.table <- xtable(summary)

print(summary.table, only.contents = TRUE, booktabs = TRUE, timestamp	= NULL, comment = FALSE, include.rownames = FALSE, file=outputFile)