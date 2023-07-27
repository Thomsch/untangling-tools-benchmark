library(tidyverse)
library(car)
library(rstatix)
library(ggpubr)
library(lme4)
library(ggbeeswarm)
library(effsize)
library(lmerTest)
library(flexplot)
library(ggplot2)
library(rsq)
#
# We use R to handle the linear mixed models because Python doesn't support lmms with 2 random effects (cross effects).
#

fileData <-"./decomposition_scores.csv"
data <- read.csv(fileData, header = FALSE, col.names = c('Project', 'BugID', 'SmartCommit', 'Flexeme', 'FileUntangling'))
data <- subset(data, select = -c(FileUntangling))
data$BugID <- as_factor(data$BugID)

# Convert to long format
data_long = pivot_longer(data, cols = 3:4, names_to = 'Tool', values_to = 'Performance')

model_mixed <- lmer(Performance ~ Tool + (1|Project) + (1|BugID), data=data_long)
summary(model_mixed)
visualize(model_mixed)
estimates(model_mixed)
rsq(model_mixed, adj=TRUE)
model_simple <- lm(Performance ~ Tool, data=data_long)
summary(model_simple)
estimates(model_simple)
visualize(model_simple)
rsq(model_simple, adj=TRUE)

model_simple2 <- lm(Performance ~ Tool + Project, data=data_long)
summary(model_simple2)
estimates(model_simple2)
visualize(model_simple2)


a = flexplot(Performance ~ Tool, data = data_long)
a
b = flexplot(therapy.type ~ 1, data = data_long)
cowplot::plot_grid(a , b)


flexplot(Performance ~ Tool, data=data_long, jitter = c(0.1,0), spread = "quartile")
#visualize(model, jitter = T, spread = "quartile")
# The summary can be interpreted as follows:
# Intercept row shows whether the baseline treatment (whichever is first) is significantly different from 0.
# The second row, containing the other treatment shows whether the other treatment is significantly different from
# the intercept.

flexplot(Performance ~ Tool | Project, data=data_long, jitter = c(0.2,0), spread = "quartile", ghost.line = 'blue') + theme(axis.text.x = element_text(angle=90, hjust=1, vjust=.2))
model <- lm(Performance ~ Tool, data=data_long)
summary(model)
visualize(model, formula = Performance ~ Tool | Project, plot = 'model', ghost.line = 'blue') + theme(axis.text.x = element_text(angle=90, hjust=1, vjust=.2))
visualize(model, formula = Performance ~ Tool, plot = 'residuals') + theme(axis.text.x = element_text(angle=90, hjust=1, vjust=.2))

# flexplot(Performance ~ BugID | Tool, data=data_long, jitter = c(0.2,0), spread = "quartile") + theme(axis.text.x = element_blank(), axis.ticks = element_blank())

estimates(model_simple)

# Effect size
cohen.d(data_long$Performance[data_long$Tool == "SmartCommit"], data_long$Performance[data_long$Tool == "Flexeme"])

#fit <- lme(Performance ~ Tool, random=c(~1|Project, ~1|BugID), data=data)
#summary(fit)

# Use random effects on Project and bug id because they are measured multiple times.
# model <- lmer(SmartCommitRand ~ FlexemeRand + (1|Project) + (1|BugID), data=data)
# summary(model)
