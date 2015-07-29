library(bbmle)
# x: number of transactions in the period (0, T] (frequency)
# t: time of last transaction (recency)

LL_DET <- function(r, alpha, a, b)
{
  p1 <- gamma(r+x) * alpha^r / (beta(a, b) * gamma(r))
  p2 <- beta(a, b+x) / (alpha + T)^(r+x) * p1
  p3 <- beta(a+1, b+x-1) / (alpha + t)^(r+x) * p1
  L  <- p2
  if(x > 0)
    L <- L + p3
  -sum(log(L))
}

fit <- mle2(LL_DET, start=list(r=1, alpha=1, a=1, b=1))