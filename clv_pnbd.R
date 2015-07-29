library(BTYD)
source("clv_header_new.R")

# Resrict the transactions to only those with repeat transactions; x > 0
# data.train <- data.train[data.train$x > 0, ]

data.train.sample <- data.train[sample(nrow(data.train), 50000, replace=FALSE),]
write.csv(data.train.sample, file='clv_data_sample.csv', row.names=FALSE)
params    <- pnbd.EstimateParameters(data.train.sample)

PlotFrequencyInTrain(params, data.train, censor=10, title="Model vs. Actual on Training")

# Jan - Mar = 12.71
# Jul - Dec = 26.28
preds    <- pnbd.ConditionalExpectedTransactions(params, T.star=12.71, data.train[, 'x'], data.train[, 't.x'], data.train[, 'T.cal'])
preds.df <- data.frame(id=data.train[, 'id'], p=preds)

compare.trans <- merge(data.test[, c('id', 'x.star')], preds.df)
compare.trans <- na.omit(compare.trans)

rmse(act=compare.trans[, "x.star"], est=compare.trans[, "p"])
msle(act=compare.trans[, "x"], est=compare.trans[, "p"])

data.validation <- merge(data.train, data.test[, c('id', 'x.star')])
data.validation <- merge(data.validation, compare.trans)
data.validation <- na.omit(data.validation)

PlotConditionalExpectedFrequency(data.validation, censor=10)

#pnbd.PlotFreqVsConditionalExpectedFrequency(params, T.star=12.71, data.validation, data.validation[, 'x.star'], censor=10)
#library(ggplot2)
#ggplot(compare.trans[compare.trans$x.star<30,], aes(x=x.star, y=p)) + 
#  geom_point(shape=1)  +  # Use hollow circles
#  geom_smooth(method=lm)



