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


fileData <-"./collated_decompositions.csv"
data <- read.csv(fileData, header = FALSE, col.names = c('Project', 'BugID', 'Treatment', 'File', 'Source', 'Target', 'Group'))
data$BugID <- as_factor(data$BugID)

#
# Number of groups in a decomposition
#
groupCount <- data %>% group_by(Project, BugID, Treatment) %>% summarise(GroupCount = n_distinct(Group))
groupCount
write.csv(groupCount, file='groupCount.csv', quote=FALSE)

# Summary of group count
groupCount %>% group_by(Treatment) %>% summarise(Min=min(GroupCount), Max=max(GroupCount), Median=median(GroupCount), Std=sd(GroupCount))

# Distribution of group count
plt <- flexplot(GroupCount ~ Treatment, data=groupCount, spread = "quartile")
plt$labels$y = "Number of Groups"
plt

#
# Size of groups in a decomposition
#
groupSize <- data %>% group_by(Project, BugID, Treatment, Group) %>% summarise(n = n())
groupSize

groupSize %>% group_by(Treatment) %>% summarise(Min=min(n), Max=max(n), Median=median(n), Std=sd(n))


plt <- flexplot(n ~ Treatment, data=groupSize, spread = "quartile")
plt$labels$y = "Group Size"
plt
