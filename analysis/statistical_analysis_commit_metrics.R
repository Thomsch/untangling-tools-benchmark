library(tidyverse)

library(effsize)
library(flexplot)

# Decomposition scores
performance.path <- './analysis/data/decomposition_scores.csv'
performance.data <- read.csv(performance.path, header = FALSE, col.names = c('project', 'bug_id', 'smartcommit_rand_index', 'flexeme_rand_index', 'file_untangling'))

# Commit metrics
metrics.path <- './analysis/data/metrics.csv'
metrics.data <- read.csv(metrics.path)

#commitMetrics.data$BugID <- as_factor(commitMetrics.data$BugID)

# Check for NA/s (they might be already existing from before)
metrics.data[rowSums(is.na(metrics.data)) > 0,]

# Join performance with metrics
performance.metrics <- left_join(performance.data, metrics.data, by = c('project' = 'project', 'bug_id' = 'vid')) %>% select(-c('file_untangling'))

# Global
performance.metrics.long = pivot_longer(performance.metrics, cols = c('smartcommit_rand_index', 'flexeme_rand_index'), names_to = 'Tool', values_to = 'Performance')

# Simple model because we proved in RQ1 that bug_id and project are not significant.
model.all <- lm(Performance ~ files_updated + hunks + average_hunk_size + code_changed_lines + tangled_lines + tangled_hunks, data=performance.metrics.long)

summary(model.all) # There is a significance in code_changed_lines, and tangled_hunks.

# files_updated
# test_files_updated
# hunks
# average_hunk_size
# code_changed_lines
# noncode_changed_lines
# tangled_lines
# tangled_hunks

summarise_model_all_variables <- function(data) {
  model <- lm(performance ~ files_updated + hunks + average_hunk_size + code_changed_lines + tangled_lines + tangled_hunks, data=data)
  summary(model)
}	

# SmartCommit All
performance.metrics.smartcommit <- select(performance.metrics, -c('flexeme_rand_index')) %>% rename(performance = smartcommit_rand_index)

summarise_model_all_variables(performance.metrics.smartcommit)

model.smartcommit.all <- lm(smartcommit_rand_index ~ files_updated + hunks + average_hunk_size + code_changed_lines + tangled_lines +             tangled_hunks, data=performance.metrics.smartcommit)

summary(model.smartcommit.all)

# Flexeme All
performance.metrics.flexeme <- select(performance.metrics, -c('smartcommit_rand_index')) %>% rename(performance = flexeme_rand_index)

model.flexeme.all <- lm(performance ~ files_updated + hunks + average_hunk_size + code_changed_lines + tangled_lines +             tangled_hunks, data=performance.metrics.flexeme)

summary(model.flexeme.all)

# -> to file impact_metrics_smartcommit_all.txt

# -> to file impact_metrics_smartcommit_individual.txt
model.smartcommit.files_updated <- lm(performance ~ files_updated, data=performance.metrics.smartcommit)
summary(model.smartcommit.files_updated)

pdf("test.pdf")
visualize(model.smartcommit.files_updated, "model", alpha = 0.1, jitter = c(0.3, .1))
dev.off()

x <- performance.metrics.smartcommit[rowSums(is.na(metrics.data)) > 0,]
model.smartcommit.files_updated <- lm(smartcommit_rand_index ~ files_updated, data=performance.metrics.smartcommit)
summary(model.smartcommit.files_updated)
visualize(model.smartcommit.files_updated, "model", alpha = 0.1, jitter = c(0.3, .1))


# Flexeme
untanglingPerformance.flexeme <- select(performance.metrics, -c('smartcommit_rand_index'))

# -> to file impact_metrics_flexeme_all.txt
model.flexeme.all <- lm(flexeme_rand_index ~ files_updated + hunks + average_hunk_size + code_changed_lines + tangled_lines +             tangled_hunks, data=untanglingPerformance.flexeme)
summary(model.flexeme.all)

# -> to file impact_metrics_flexeme_individual.txt

# WIP


model.hunks.tangled <- lm(flexeme_rand_index ~ tangled_hunks, data=untanglingPerformance.flexeme.tangled_hunks)

summary(model.hunks.tangled)
visualize(model.hunks.tangled)

untanglingPerformance.flexeme.tangled_hunks <- select(untanglingPerformance.flexeme, c(flexeme_rand_index, tangled_hunks)) %>% subset(tangled_hunks > 0)

flexplot(tangled_hunks ~ 1, data=untanglingPerformance.flexeme)

summary(model.hunks.tangled)
estimates(model.hunks.tangled)
visualize(model.hunks.tangled)


# TODO: Call cohen.d() for statistically significant results only.
cohen.d(data_long$average_hunk_size, data_long$Performance)
cohen.d(data_long$lines_updated, data_long$Performance)
