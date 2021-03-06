#' Ten datasets obtained by resampling the S&P 500
#' 
#' Ten datasets of stock market data resampled from the S&P 500. 
#' Each resample contains a random selection of 50 stocks from the S&P 500 
#' universe and a period of two years with a random initial point.
#'
#' @docType data
#'
#' @usage data(dataset10)
#'
#' @format List of 10 datasets, each contains two \code{xts} objects:
#' \describe{
#'   \item{adjusted}{505 x 50 \code{xts} with the adjusted prices of the 50 stocks}
#'   \item{index}{505 x 1 \code{xts} with the market index prices}
#' }
#'
#' @source \href{https://finance.yahoo.com}{Yahoo! Finance}
#'
#' @keywords dataset
#'
"dataset10"
