#' @title Download stock data from the Internet
#'
#' @description This function is basically a robust wrapper for 
#' \code{\link[quantmod:getSymbols]{quantmod:getSymbols}} to download stock 
#' data from the internet. It will return 6 \code{xts} objects of the same 
#' dimensions named `open`, `high`, `low`, `close`, `volume`, `adjusted` 
#' and `index`. Additionally, it can return an \code{xts} object with an 
#' index. If the download for some stock fails after a few attempts they 
#' will be ignored and reported. Also, stocks with missing values can be 
#' optionally removed.
#' 
#' @param stock_symbols String vector containing the symbols of the stocks to be downloaded.
#'                      User can pass the market index symbol as its attribute `index_symbol`` 
#'                      (only considered when argument `index_symbol` is not passed).
#' @param index_symbol String of the market index symbol. 
#' @param from String as the starting date, e.g., "2017-08-17".
#' @param to String as the ending date (not included), e.g., "2017-09-17".
#' @param rm_stocks_with_na Logical value indicating whether to remove stocks with missing values 
#'                          (ignoring leading missing values). Default is \code{TRUE}.
#' @param local_file_path Path where the stock data will be saved after the first time is downloaded, 
#'                        so that in future retrievals it will be locally loaded (if the same 
#'                        arguments are used). Default is \code{getwd()}. If local caching is not 
#'                        desired, it can be deactivated by setting \code{local_file_path = NULL}.
#' @param ... Additional arguments to be passed to \code{\link[quantmod:getSymbols]{quantmod:getSymbols}}.
#'
#' @return List of 7 \code{xts} objects named `open`, `high`, `low`, `close`, `volume`, 
#'         `adjusted` and `index`. Note that `index` will only be returned when correct index symbols is passed.
#' 
#' @author Rui Zhou and Daniel P. Palomar
#' 
#' @seealso \code{\link{financialDataResample}}
#' 
#' @examples
#' \dontrun{
#' library(portfolioBacktest)
#' data(SP500_symbols)
#' 
#' # download data from internet
#' SP500_data <- stockDataDownload(stock_symbols = SP500_symbols,
#'                                 from = "2009-01-01", to = "2009-12-31")
#' }
#' 
#' @import xts 
#'         quantmod
#'         digest
#' @export
stockDataDownload <- function(stock_symbols, index_symbol = NULL, from, to, rm_stocks_with_na = TRUE, local_file_path = getwd(), ...) {
  # some error control
  if (missing(from) || missing(to)) stop("Arguments from and to have to be passed.")
  
  # first check if data locally saved
  if (!is.null(local_file_path)) {
    sorted_stock_symbols <- sort(stock_symbols)
    attributes(sorted_stock_symbols) <- attributes(stock_symbols)
    hash_stock_symbols <- digest(stock_symbols)
    filename <- file.path(local_file_path,
                          paste0("stockdata", "_from_", from, "_to_", to, "_(", hash_stock_symbols, ").RData"))
    if (file.exists(filename)) {
      message("Loading stock data from local file ", filename)
      load(filename)
      return(stockdata)
    }
  }
  
  # if not continue to download data
  open <- high <- low <- close <- volume <- adjusted <- list()
  n_stocks <- length(stock_symbols)
  message("Downloading ", n_stocks, " stocks...")
  
  sink(file = tempfile())
  pb <- utils::txtProgressBar(max = n_stocks, style = 3)
  sink()

  valid_count <- 0
  stocks_fail <- c()
  for (i in 1:n_stocks) {
    tmp <- tryCatch(suppressWarnings(getSymbols(stock_symbols[i], from = from, to = to, auto.assign = FALSE, warnings = FALSE, ...)),
                    error = function(e) return(NULL))
    if (!is.xts(tmp) || !is.OHLCV(tmp) || ncol(tmp) != 6) 
      stocks_fail <- c(stocks_fail, stock_symbols[i])
    else {
      valid_count <- valid_count + 1
      open[[valid_count]]     <- tmp[, 1]  #Op(tmp)
      high[[valid_count]]     <- tmp[, 2]  #Hi(tmp)
      low[[valid_count]]      <- tmp[, 3]  #Lo(tmp)  <- this fails is the name of the stock is "LOW", it's a bug in quantmod
      close[[valid_count]]    <- tmp[, 4]  #Cl(tmp)
      volume[[valid_count]]   <- tmp[, 5]  #Vo(tmp)
      adjusted[[valid_count]] <- tmp[, 6]  #Ad(tmp)
    }
    utils::setTxtProgressBar(pb, i)
  }

  # show download information
  message("\nSuccesses: ", valid_count, "\t fails: ", n_stocks - valid_count, "\n")
  if (valid_count == 0) stop("Failed to download data from any stock.", call. = FALSE)
  if (valid_count < n_stocks) message("Failed to download: ", paste0(stocks_fail, collapse = ", "), "\n")
  
  stockdata <- list("open"     = multipleXTSMerge(open),
                    "high"     = multipleXTSMerge(high),
                    "low"      = multipleXTSMerge(low),
                    "close"    = multipleXTSMerge(close),
                    "volume"   = multipleXTSMerge(volume),
                    "adjusted" = multipleXTSMerge(adjusted))
  
  # fix names of stocks in each xts
  if ("open" %in% names(stockdata))
    colnames(stockdata$open) <- gsub(".Open", "", colnames(stockdata$open))
  if ("high" %in% names(stockdata))
    colnames(stockdata$high) <- gsub(".High", "", colnames(stockdata$high))
  if ("low" %in% names(stockdata))
    colnames(stockdata$low) <- gsub(".Low", "", colnames(stockdata$low))
  if ("close" %in% names(stockdata))
    colnames(stockdata$close) <- gsub(".Close", "", colnames(stockdata$close))
  if ("volume" %in% names(stockdata))
    colnames(stockdata$volume) <- gsub(".Volume", "", colnames(stockdata$volume))
  if ("adjusted" %in% names(stockdata))
    colnames(stockdata$adjusted) <- gsub(".Adjusted", "", colnames(stockdata$adjusted))  
  
  # if required, remove stocks with non-leading missing data
  if (rm_stocks_with_na) {
    na_nonleading_mask <- apply(stockdata$adjusted, 2, function(x) {any(diff(is.na(x)) > 0)})
    stockdata <- lapply(stockdata, function(x) {x[, !na_nonleading_mask]})
  }
  
  # sanity check
  ncols <- sapply(stockdata, ncol)
  if (any(ncols[1] != ncols[-1])) stop("Number of cols of Op, Hi, Lo, Vo, Ad does not coincide!")
      
  
  # also download index data
  if (is.null(index_symbol)) index_symbol <- attr(stock_symbols, "index_symbol")  
  if (!is.null(index_symbol)) {
    message("Downloading index ", index_symbol, "...\n")
    stockdata$index <- tryCatch(Ad(suppressWarnings(getSymbols(index_symbol, from = from, to = to, auto.assign = FALSE, ...))),
                         error = function(e) {stop("Failed to download index \"", index_symbol, "\"\n", call. = FALSE)})
    # check if the date of stock prices and market index match
    if (any(index(stockdata$adjusted) != index(stockdata$index)))
      stop("Date of stocks prices and market index do not match.", call. = FALSE)
    
    # fix name of index xts
    colnames(stockdata$index) <- gsub(".Adjusted", "", colnames(stockdata$index))
  }
  
  # sanity check
  nrows <- sapply(stockdata, nrow)
  if (any(nrows[1] != nrows[-1])) stop("Number of rows of Op, Hi, Lo, Vo, Ad (or Index) does not coincide!")
  
  # save to local file if necessary for future usage
  if (!is.null(local_file_path)) {
    message("Saving stock data to local file ", filename, " for future use.")
    save(stockdata, file = filename)
  }

  return(stockdata)
}


multipleXTSMerge <- function(xts_list) {
  res <- xts_list[[1]]
  if (length(xts_list) == 1) return(res)
  for (i in 2:length(xts_list))
    res <- xts::merge.xts(res, xts_list[[i]], join = "outer")
  return(res)
}



#' @title Generate random resamples from financial data
#' 
#' @description This function resamples the financial data (e.g., downloaded 
#' with \code{\link{stockDataDownload}}) to obtain many datasets for a 
#' subsequent backtesting with \code{\link{portfolioBacktest}}.
#' Given the original data, each resample is obtained by randomly
#' choosing a subset of the financial instruments and randomly choosing a
#' time period over the available long period.
#' 
#' @param X List of \code{xts} objects matching the structure returned by the function \code{\link{stockDataDownload}}.
#' @param N_sample Desired number of financial instruments in each resample.
#' @param T_sample Desired length of each resample (consecutive samples with a random initial time).
#' @param num_datasets Number of resampled datasets (chosen randomly among the financial instrument universe).
#' @param rm_stocks_with_na Logical value indicating whether to remove instruments with inner missing 
#'                          values. Default is \code{TRUE}.
#' 
#' @return List of datasets resampled from \code{X}.
#' 
#' @author Rui Zhou and Daniel P. Palomar
#' 
#' @seealso \code{\link{stockDataDownload}}, \code{\link{portfolioBacktest}}
#' 
#' @examples 
#' \dontrun{
#' library(portfolioBacktest)
#' data(SP500_symbols)
#' 
#' # download data from internet
#' SP500_data <- stockDataDownload(stock_symbols = SP500_symbols, 
#'                                 from = "2009-01-01", to = "2009-12-31") 
#'                                 
#' # generate 20 resamples from data, each with 10 stocks and one quarter continuous data
#' my_dataset_list <- financialDataResample(SP500_data, N = 10, T = 252/4, num_datasets = 20)
#' }
#' 
#' @import xts
#'         zoo
#' @importFrom utils head
#' @export
financialDataResample <- function(X, N_sample = 50, T_sample = 2*252, num_datasets = 10, rm_stocks_with_na = TRUE) {
  # error control for indices
  X_index_list <- lapply(X, function(x) index(x))
  X_equal_indices_list <- sapply(X_index_list, function(x) identical(x, X_index_list[[1]]))
  if (!all(X_equal_indices_list)) 
    stop("The date indices of \"X\" do not match.")

  # separate univariate from multivariate
  num_cols <- sapply(X, ncol)
  N <- max(num_cols)  # some elements will have N cols, others just 1
  elems_N <- which(num_cols == N)
  elems_1 <- setdiff(1:length(X), elems_N)
  
  # # if required, check inner NAs
  # if (rm_stocks_with_na) {   
  #   inner_NA_pattern <- sapply(X[elems_N], function(x) apply(x, 2, any_inner_NA))
  #   columns_to_keep <- rowSums(inner_NA_pattern) == 0
  #   if (any(!columns_to_keep)) 
  #     warning("Some xts object does not satisfy monotone missing-data pattern.\n", call. = FALSE)
  #   #X[elems_N] <- apply(X[elems_N], function(x) x[, columns_to_keep])
  #   #N <- ncol(X[[elems_N[1]]])
  # }
  
  # resampling blocks (without NAs)
  T <- nrow(X[[1]])
  if (T < T_sample) 
    stop("\"T_sample\" cannot be greater than the date length of \"X\".")
  dataset <- vector("list", num_datasets)
  for (i in 1:num_datasets) {
    # random time period
    t_start <- sample(T - T_sample + 1, 1)
    t_mask <- t_start:(t_start + T_sample - 1)
    # random stocks
    idx_cols <- if (rm_stocks_with_na) which(!apply(X[[1]][t_mask, ], 2, anyNA))
                else 1:N
    if (length(idx_cols) == 0)
      stop("Time period without any stock without NAs!")
    stock_mask <- if (length(idx_cols) <= N_sample) idx_cols
                  else sample(idx_cols, N_sample)
    
    dataset[[i]] <- vector("list", length(X))
    names(dataset[[i]]) <- names(X)
    dataset[[i]][elems_N] <- lapply(X[elems_N], function(x) x[t_mask, stock_mask])
    if (length(elems_1) > 0) dataset[[i]][elems_1] <- lapply(X[elems_1], function(x) x[t_mask, ])
  }
  names(dataset) <- paste("dataset", 1:num_datasets)
  message(sprintf("%d datasets resampled (with N = %d instruments and length T = %d) from the original data between %s and %s.", 
                  num_datasets, N_sample, T_sample, paste(head(X_index_list[[1]], 2))[1], last(X_index_list[[1]])))

  return(dataset)
}



#' @title Generate random resamples from financial data
#' 
#' @description This function is deprecated. Use instead \code{\link{financialDataResample}()}.
#' 
#' @inheritParams financialDataResample
#' 
#' @export
stockDataResample <- function(X, N_sample = 50, T_sample = 2*252, num_datasets = 10, rm_stocks_with_na = TRUE) {
  .Deprecated("financialDataResample")
}


any_inner_NA <- function (y) {
  idx_obs <- which(!is.na(y))
  if (length(idx_obs) == 0) 
    return(FALSE)
  else anyNA(y[min(idx_obs):max(idx_obs)])
}
