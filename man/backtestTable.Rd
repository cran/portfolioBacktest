% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/backtestSummary.R
\name{backtestTable}
\alias{backtestTable}
\title{Table with portfolio backtest results}
\usage{
backtestTable(
  bt,
  portfolio_indexes = NA,
  portfolio_names = NA,
  show_benchmark = TRUE,
  measures = NULL
)
}
\arguments{
\item{bt}{Backtest results as produced by the function \code{\link{portfolioBacktest}}.}

\item{portfolio_indexes}{Numerical vector of portfolio indexes whose performance will be summarized, 
e.g., \code{c(1, 2)} means to summarize the performance of the first and 
second portfolios recorded in \code{bt}.}

\item{portfolio_names}{String vector of portfolio names whose performance will be summarized, 
e.g., \code{c("EWP", "GMVP")} means to summarize the performance of portfolios
with names \code{"EWP"} and \code{"GMVP"} in \code{bt} (default is 
\code{names(bt)} except the benchmark names). Only considered when 
\code{portfolio_indexes} is not passed.}

\item{show_benchmark}{Logical value indicating whether to include benchmarks in the summary (default is \code{TRUE}).}

\item{measures}{String vector to select performane measures (default is all) from
\code{"Sharpe ratio"}, \code{"max drawdown"}, \code{"annual return"}, \code{"annual volatility"}, 
\code{"Sterling ratio"}, \code{"Omega ratio"}, \code{"ROT bps"},
\code{"error"}, \code{"cpu time"}, and \code{"error_message"}.}
}
\value{
List with the following elements:
\item{\code{<performance criterion>}}{One item per performance measures as selected by argument \code{measures}.}
\item{\code{error}}{Error status (\code{TRUE} or \code{FALSE}) for each portfolio over each dataset
                   (\code{TRUE} is when the portfolio function generates an error or the maximum CPU time is exceeded).}
\item{\code{cpu time}}{CPU usage by each portfolio function over each dataset.}
\item{\code{error_message}}{Error messages generated by each portfolio function over each dataset.
                            Useful for debugging purposes.}
}
\description{
Create table with the results from a portfolio backtest.
}
\examples{
\donttest{
library(portfolioBacktest)
data(dataset10)  # load dataset

# define your own portfolio function
EWP_portfolio <- function(dataset, ...) {
  N <- ncol(dataset$adjusted)
  return(rep(1/N, N))
}

# do backtest
bt <- portfolioBacktest(list("EWP" = EWP_portfolio), dataset10)

# show the backtest results in table
bt_tab <- backtestTable(bt)
bt_tab[c("Sharpe ratio", "max drawdown")]
}

}
\author{
Rui Zhou and Daniel P. Palomar
}
