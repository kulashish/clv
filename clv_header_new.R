tocbs <- function(data, cal.date){
  end.cal.period <- as.Date(cal.date, format="%Y-%m-%d")
  data['t.x']    <- as.numeric(difftime(strptime(data$end_date, format = "%Y-%m-%d"), strptime(data$start_date, format = "%Y-%m-%d"), units="weeks"))
  data['T.cal']  <- as.numeric(difftime(end.cal.period, strptime(data$start_date, format = "%Y-%m-%d"), units="weeks"))
  data['x']      <- data['x'] - 1
  data           <- data[, c(1,2,3,4,7)]
  #  cbs            <- as.matrix(data[, c(3,2,7)])
}
#data.train <- read.csv('/data/clv_data_train.gz', header=F, col.names=c('id', 't.x', 'x', 'm', 'start_date', 'end_date'), colClasses=c('character', 'numeric', 'numeric', 'numeric', 'character', 'character'))
#data.train <- tocbs(data.train, '2014-06-30')
data.train <- read.csv('/data/clv_train_year.gz', header=F, col.names=c('id', 't.x', 'x', 'm', 'start_date', 'end_date'), colClasses=c('character', 'numeric', 'numeric', 'numeric', 'character', 'character'))
data.train <- tocbs(data.train, '2014-12-31')
#data.train          <- data.train[, c(1,2,3,7)]

#data.test <- read.csv('/data/clv_data_test.gz', header=F, col.names=c('id', 't.x', 'x', 'm', 'start_date', 'end_date'), colClasses=c('character', 'numeric', 'numeric', 'numeric', 'character', 'character'))
#data.test <- tocbs(data.test, '2014-12-31')
data.test <- read.csv('/data/clv_test_qtr.gz', header=F, col.names=c('id', 't.x', 'x', 'm', 'start_date', 'end_date'), colClasses=c('character', 'numeric', 'numeric', 'numeric', 'character', 'character'))
data.test <- tocbs(data.test, '2015-03-31')
colnames(data.test)[3] <- 'x.star'

# root mean squared error
rmse <- function(est, act) { return(sqrt(mean((est-act)^2))) }

# mean squared logarithmic error
msle <- function(est, act) { return(mean((log1p(est)-log1p(act))^2)) }

PlotConditionalExpectedFrequency <- function(result.data, censor, xticklab = NULL, title = "Conditional Expectation") {
  #result.data <- data.validation
  #censor <- 10
  x <- result.data[, 'x']
  x.star <- result.data[, 'x.star']
  p <- result.data[, 'p']
  
  n.bins <- censor + 1
  transaction.actual <- rep(0, n.bins)
  transaction.expected <- rep(0, n.bins)
  bin.size <- rep(0, n.bins)
  
  for (cc in 0:censor) {
    if (cc != censor) {
      this.bin <- which(cc == x)
    } else if (cc == censor) {
      this.bin <- which(x >= cc)
    }
    n.this.bin <- length(this.bin)
    bin.size[cc + 1] <- n.this.bin
    
    transaction.actual[cc + 1] <- sum(x.star[this.bin])/n.this.bin
    transaction.expected[cc + 1] <- sum(p[this.bin])/n.this.bin
  }
  x.labels <- 0:(censor)
  x.labels[censor + 1] <- paste(censor, "+", sep = "")
  ylim <- c(0, ceiling(max(c(transaction.actual, transaction.expected)) * 1.1))
  xlab <- 'Frequency in training period'
  ylab <- 'Frequency in validation period'
  plot(transaction.actual, type = "l", xaxt = "n", col = 1, ylim=ylim, xlab=xlab, ylab=ylab)
  axis(1, at = 1:length(transaction.actual), labels = x.labels)
  lines(transaction.expected, lty = 2, col = 2)
  legend("topleft", legend = c("Actual", "Model"), col = 1:2, lty = 1:2, lwd = 1)
}

PlotFrequencyInTrain <- function(params, cal.cbs, censor, plotZero = FALSE, 
                                 xlab = "Training period transactions", ylab = "Users", title = "Frequency of Repeat Transactions") {
  cal.cbs <- na.omit(cal.cbs)
  tryCatch(x <- cal.cbs[, "x"], error = function(e) stop("Error in pnbd.PlotFrequencyInCalibration: cal.cbs must have a frequency column labelled \"x\""))
  tryCatch(T.cal <- cal.cbs[, "T.cal"], error = function(e) stop("Error in pnbd.PlotFrequencyInCalibration: cal.cbs must have a column for length of time observed labelled \"T.cal\""))
  
  dc.check.model.params(c("r", "alpha", "s", "beta"), params, "pnbd.PlotFrequencyInCalibration")
  if (censor > max(x)) 
    stop("censor too big (> max freq) in PlotFrequencyInCalibration.")
  
  n.x <- rep(0, max(x) + 1)
  custs = nrow(cal.cbs)
  
  for (ii in unique(x)) {
    n.x[ii + 1] <- sum(ii == x)
  }
  
  n.x.censor <- sum(n.x[(censor + 1):length(n.x)])
  n.x.actual <- c(n.x[1:censor], n.x.censor)
  
  T.value.counts <- table(T.cal)
  T.values <- as.numeric(names(T.value.counts))
  n.T.values <- length(T.values)
  
  total.probability <- 0
  
  n.x.expected <- rep(0, length(n.x.actual))
  
  for (ii in 1:(censor)) {
    this.x.expected <- 0
    for (T.idx in 1:n.T.values) {
      T <- T.values[T.idx]
      if (T == 0) 
        next
      n.T <- T.value.counts[T.idx]
      expected.given.x.and.T <- n.T * pnbd.pmf(params, T, ii - 1)
      if(!is.nan(expected.given.x.and.T)){
        this.x.expected <- this.x.expected + expected.given.x.and.T
        total.probability <- total.probability + expected.given.x.and.T/custs
      }
    }
    n.x.expected[ii] <- this.x.expected
  }
  n.x.expected[censor + 1] <- custs * (1 - total.probability)
  
  col.names <- paste(rep("freq", length(censor + 1)), (0:censor), sep = ".")
  col.names[censor + 1] <- paste(col.names[censor + 1], "+", sep = "")
  censored.freq.comparison <- rbind(n.x.actual, n.x.expected)
  colnames(censored.freq.comparison) <- col.names
  
  cfc.plot <- censored.freq.comparison
  
  if (plotZero == FALSE) 
    cfc.plot <- cfc.plot[, -1]
  
  n.ticks <- ncol(cfc.plot)
  if (plotZero == TRUE) {
    x.labels <- 0:(n.ticks - 1)
    x.labels[n.ticks] <- paste(n.ticks - 1, "+", sep = "")
  } else {
    x.labels <- 1:(n.ticks)
    x.labels[n.ticks] <- paste(n.ticks, "+", sep = "")
  }
  
  ylim <- c(0, ceiling(max(cfc.plot) * 1.1))
  barplot(cfc.plot, names.arg = x.labels, beside = TRUE, ylim = ylim, main = title, 
          xlab = xlab, ylab = ylab, col = 1:2)
  
  legend("topright", legend = c("Actual", "Model"), col = 1:2, lwd = 2)
}