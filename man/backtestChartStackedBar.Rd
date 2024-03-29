% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotsNtables.R
\name{backtestChartStackedBar}
\alias{backtestChartStackedBar}
\title{Chart of the weight allocation over time for a portfolio over a single backtest}
\usage{
backtestChartStackedBar(
  bt,
  portfolio = names(bt[1]),
  dataset_num = 1,
  num_bars = 100,
  type = c("ggplot2", "simple"),
  legend = FALSE
)
}
\arguments{
\item{bt}{Backtest results as produced by the function \code{\link{portfolioBacktest}}.}

\item{portfolio}{String with portfolio name to be charted. 
Default charts the first portfolio in the backtest.}

\item{dataset_num}{Dataset index to be charted. Default is \code{dataset_num = 1}.}

\item{num_bars}{Number of bars shown over time (basically a downsample of the possibly long sequence).}

\item{type}{Type of plot. Valid options: \code{"ggplot2", "simple"}. Default is 
\code{"ggplot2"}.}

\item{legend}{Boolean to choose whether legend is plotted or not. Default is \code{legend = FALSE}.}
}
\description{
Create chart of the weight allocation over time for a portfolio over a single 
backtest obtained with the function \code{\link{portfolioBacktest}}.
By default the chart is based on the package \code{ggplot2}, but the user can also 
specify a plot based on \code{PerformanceAnalytics}.
}
\examples{
\donttest{
library(portfolioBacktest)
data(dataset10)  # load dataset

# for better illustration, let's use only the first 5 stocks
dataset10_5stocks <- lapply(dataset10, function(x) {x$adjusted <- x$adjusted[, 1:5]; return(x)})

# define GMVP (with heuristic not to allow shorting)
GMVP_portfolio_fun <- function(dataset, ...) {
  X <- diff(log(dataset$adjusted))[-1]  # compute log returns
  Sigma <- cov(X)  # compute SCM
  # design GMVP
  w <- solve(Sigma, rep(1, nrow(Sigma)))
  w <- abs(w)/sum(abs(w))
  return(w)
}

# backtest
bt <- portfolioBacktest(list("GMVP" = GMVP_portfolio_fun), dataset10_5stocks, rebalance_every = 20)

# now we can chart
backtestChartStackedBar(bt, "GMVP", type = "simple")
backtestChartStackedBar(bt, "GMVP", type = "simple", legend = TRUE)
backtestChartStackedBar(bt, "GMVP")
backtestChartStackedBar(bt, "GMVP", legend = TRUE)
}

}
\seealso{
\code{\link{summaryBarPlot}}, \code{\link{backtestBoxPlot}}, 
         \code{\link{backtestChartCumReturn}}, \code{\link{backtestChartDrawdown}}
}
\author{
Daniel P. Palomar and Rui Zhou
}
