#' Calculate relative error
#'
#' Calculate the relative error (RE; [EM - OM]/OM) of 
#' parameters and derived quantities stored in a scalar or time series 
#' data frame generated by \code{\link{get_results_all}}.
#'
#' @param dat An input data frame. Should be either a scalar or time series
#'   data frame as returned from \code{\link{get_results_all}} or a related
#'   get results function. Specifically, the data frame needs to have columns
#'   with \code{_em} and \code{_om} as names. If the data is provided in long
#'   rather than wide format, then \code{\link{convert_to_wide}} will be used
#'   internally before calculating RE and a wide data frame will be returned.
#' @param add Logical: should the relative error columns be added to \code{dat}
#'   or should the original EM and OM columns be dropped? If \code{FALSE} then
#'   the returned data frame will have only the identifying columns and the new
#'   relative error columns. You could then merge selected columns back into
#'   \code{dat} if you wished. The default is to return all columns.
#' @param EM A character value specifying the name of the EM to calculate the
#'   RE of when the results are provided in long format and there is the potential
#'   for multiple EMs. See the column \code{model_run} for options.
#' @author Sean Anderson and Cole Monnahan
#' @seealso \code{\link{get_results_all}}, \code{link{get_results_scenario}}
#' @return The default is to return a data frame structured the same as the 
#' input data frame, i.e., \code{dat}, but with additional columns, where 
#' \code{'_re'} is appended to the base string of the column name.
#' All \code{NAN} and \code{Inf} values are returned as \code{NA} values,
#' typically because you cannot divide by zero. Irrelevant columns, i.e.,
#' columns of entirely zero of \code{NA} are removed prior to returning the
#' data frame.
#' @export
#' @examples
#' # Example with built in package data:
#' data("ts_dat", package = "ss3sim")
#' data("scalar_dat", package = "ss3sim")
#' head(calculate_re(ts_dat))
#' head(calculate_re(ts_dat, add = FALSE))
#' head(calculate_re(scalar_dat, add = FALSE))
#' rm("ts_dat", "scalar_dat")
#'
calculate_re <- function(dat, add = TRUE, EM = "em") {

  # Check if wide or long data
  if ("model_run" %in% colnames(dat)) {
    stopifnot(length(EM) == 1)
    dat <- convert_to_wide(dat[dat$model_run %in% c("om", EM), ])
  }
  both <- intersect(
    gsub("_em", "", grep("_em", names(dat), value = TRUE)),
    gsub("_om", "", grep("_om", names(dat), value = TRUE)))
  both <- both[order(both)]
  em_names <- paste0(both, "_em")
  om_names <- paste0(both, "_om")

  re <- (dat[, em_names] - dat[, om_names]) /
    dat[, om_names]
  names(re) <- gsub("_em", "_re", names(re))

  # strip out NLL
  # strip out columns of all NAs or zeros
  re <- re[, !grepl("NLL", names(re))]
  re[is.na(re)] <- NA
  re[is.infinite(as.matrix(re))] <- NA
  re <- re[, apply(re, 2, function(x) !all(x %in% c(NA, 0)))]
  # Remove all OM and EM columns if only returning RE
  if (!add) {
    data.frame(dat[, !grepl("_om|_em", colnames(dat))], re)
  } else {
    data.frame(dat, re)
  }
}
