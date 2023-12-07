#!/usr/bin/env Rscript
#
# Run and export the statistical analysis for the untangling tools with p-value, Cohen's d, R^2, and model residuals normality test results.
# The statistical analysis results are saved in two files:
# - `outputDir/untangling_tool_performance_statistical_analysis.txt` contains the summary of the model, ANOVA, Shapiro-Wilk normality test, and Cohen's d.
# - `outputDir/untangling_tool_performance_residuals.pdf` contains the residual plots of the model.
#
# Arguments:
# - 1: The untangling performance file `decomposition_scores.csv` containing the performance of the untangling tools for a dataset.
# - 1: The path to the directory where the analysis results will be saved.
#
# Output:
# The results are saved as text data. The output file contains
# the output of the summary() and cohen.d() functions.

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=2) {
  stop("Please provide the untangling performance file and the path where to store the results. Example: 'statistical_analysis_untangling_tool.R tool_performance.csv analysis/'", call.=FALSE)
}
untanglingPerformanceFile = args[1]
outputDir= args[2]

residuals_plot_file = paste(outputDir, "untangling_tool_performance_residuals.pdf", sep="/")
untangling_tool_performance_statistical_analysis_file = paste(outputDir, "untangling_tool_performance_statistical_analysis.txt", sep="/")

library(librarian)
library(tidyverse)
library(car)
library(ggpubr)
library(lme4)
library(effsize)
library(lmerTest)
library(flexplot)
library(rsq)
shelf(broom)

data <- read.csv(untanglingPerformanceFile, header = FALSE, col.names = c('Project', 'BugID', 'SmartCommit', 'Flexeme', 'FileUntangling'))
data <- subset(data, select = -c(FileUntangling))
data$BugID <- as_factor(data$BugID)

# Convert to long format and select only SmartCommit and Flexeme to compare.
data_long = pivot_longer(data, cols = c('SmartCommit', 'Flexeme'), names_to = 'Tool', values_to = 'Performance')

# The summary can be interpreted as follows:
# Intercept row shows whether the baseline treatment (whichever is first) is significantly different from 0.
# The second row, containing the other treatment, shows whether the other treatment is significantly
# different from the intercept.
model <- lm(Performance ~ Tool, data=data_long)

# Residuals
# It is recommended to look at the residuals to check for normality rather than apply a statistical test.
pdf(residuals_plot_file)
visualize(model, "residuals")
dev.off()

# Analysis results
sink(untangling_tool_performance_statistical_analysis_file)
summary(model)
anova(model)
shapiro.test(residuals(model))
cohen.d(data_long$Performance[data_long$Tool == "SmartCommit"], data_long$Performance[data_long$Tool == "Flexeme"])
sink()

