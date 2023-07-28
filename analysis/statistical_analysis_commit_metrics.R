library(tidyverse)
library(car)
library(rstatix)
library(ggpubr)
library(lme4)
library(ggbeeswarm)
library(effsize)

#
# We load directly in the long format because I already written the code in Python for it :).
# To generate the file, run the jupyter notebook in this folder.
#

library(lmerTest)

fileData <-"./merge.csv"
data <- read.csv(fileData)
data <- na.omit(data)


# Convert to long format
data_long = pivot_longer(data, cols = c(smartcommit_rand_index, flexeme_rand_index), names_to = 'Treatment', values_to = 'Performance')

model <- lmer(Performance ~ Treatment + files_updated + test_files_updated + hunks + average_hunk_size + lines_updated + (1|project) + (1|bug_id), data=data_long)
summary(model)

cohen.d(data_long$average_hunk_size, data_long$Performance)
cohen.d(data_long$lines_updated, data_long$Performance)
