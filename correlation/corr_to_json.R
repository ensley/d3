library(jsonlite)
library(corrplot)

train <- readRDS('train_nomiss.rds')
numerics <- names(train)[!sapply(train, is.factor)]
numerics <- numerics[which(numerics != 'Id')]
dat <- train[ ,numerics]

corr <- cor(dat)

ind <- rownames(dat)
vars <- colnames(dat)

ord <- corrMatOrder(corr, order = 'hclust')
dat_ordered <- dat[ ,ord]
corr_ordered <- cor(dat_ordered)

result <- list('ind' = toJSON(ind),
               'vars' = toJSON(vars[ord]),
               'corr' = toJSON(corr_ordered),
               'dat' = toJSON(t(dat_ordered)))

y <- paste0('{', paste0('"', names(result), '": ', result, collapse = ','), '}')

cat(y, file='data/housing.json')
