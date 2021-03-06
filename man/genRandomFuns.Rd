% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/param_tuning.R
\name{genRandomFuns}
\alias{genRandomFuns}
\title{Generate multiple versions of a function with randomly chosen parameters}
\usage{
genRandomFuns(portfolio_fun, params_grid, name = "portfolio", N_funs = NULL)
}
\arguments{
\item{portfolio_fun}{Portfolio function with parameters unspecified.}

\item{params_grid}{Named list containing for each parameter the possible values it can take.}

\item{name}{String with the name of the portfolio function.}

\item{N_funs}{Number of functions to be generated.}
}
\description{
Portfolio functions usually contain some parameters that can be tuned. 
This function creates multiple versions of a function with randomly chosen parameters.
After backtesting those portfolios, the plotting function \code{\link{plotPerformanceVsParams}} 
can be used to show the performance vs parameters.
}
\examples{
library(portfolioBacktest)

# define GMVP with parameters "delay", "lookback", and "regularize"
GMVP_portfolio_fun <- function(dataset) {
  prices <- tail(lag(dataset$adjusted, delay), lookback)
  X <- diff(log(prices))[-1]
  Sigma <- cov(X)
  if (regularize)
    Sigma <- Sigma + 0.1 * mean(diag(Sigma)) * diag(ncol(Sigma))
  # design GMVP
  w <- solve(Sigma, rep(1, ncol(Sigma)))
  return(w/sum(w))
}

# generate the functions with random parameters
portfolio_list <- genRandomFuns(portfolio_fun = GMVP_portfolio_fun, 
                                params_grid = list(lookback = c(100, 120, 140, 160),
                                                   delay = c(0, 5, 10, 15, 20),
                                                   regularize = c(FALSE, TRUE)),
                                name = "GMVP", 
                                N_funs = 40)
names(portfolio_list)
portfolio_list[[1]]
rlang::env_print(portfolio_list[[1]])
rlang::fn_env(portfolio_list[[1]])$lookback
rlang::fn_env(portfolio_list[[1]])$delay
rlang::fn_env(portfolio_list[[1]])$regularize

}
\seealso{
\code{\link{plotPerformanceVsParams}}
}
\author{
Daniel P. Palomar and Rui Zhou
}
