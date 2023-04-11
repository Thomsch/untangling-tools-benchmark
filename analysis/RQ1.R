library(tidyverse)
library(car)
library(rstatix)
library(ggpubr)
library(lme4)
library(ggbeeswarm)
library(effsize)
library(lmerTest)
#
# We use R to handle the linear mixed models because Python doesn't support lmms with 2 random effects (cross effects).
#


fileData <-"./decompositions.csv"
data <- read.csv(fileData, header = FALSE, col.names = c('Project', 'BugID', 'SmartCommit', 'Flexeme'))

# Convert to long format
data_long = pivot_longer(data, cols = 3:4, names_to = 'Treatment', values_to = 'Performance')

ggplot(data_long, aes(x=Treatment, y=Performance)) + geom_beeswarm() + coord_flip()

model <- lmer(Performance ~ Treatment + (1|Project) + (1|BugID), data=data_long)
summary(model)

# Effect size
cohen.d(data_long$Performance[data_long$Treatment == "SmartCommit"], data_long$Performance[data_long$Treatment == "Flexeme"])

#fit <- lme(Performance ~ Treatment, random=c(~1|Project, ~1|BugID), data=data)
#summary(fit)

# Use random effects on Project and bug id because they are measured multiple times.
# model <- lmer(SmartCommitRand ~ FlexemeRand + (1|Project) + (1|BugID), data=data)
# summary(model)
