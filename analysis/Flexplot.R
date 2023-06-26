# install.packages("devtools")
# devtools::install_github("dustinfife/flexplot")

library(flexplot)
data(relationship_satisfaction)

### multivariate relationship
flexplot(satisfaction~communication + separated | gender + interests, data=relationship_satisfaction)

flexplot(gender~1, data=relationship_satisfaction)

fileData <-"./lines.csv"
data <- read.csv(fileData, header = FALSE, col.names = c('project','bug_id','fix_lines','other_lines'))

flexplot(project~1, data=data)