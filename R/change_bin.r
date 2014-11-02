#' Change the data that is available as output from an SS operating model.
#'
#' \code{change_bin} alters the bin structure for the age or length composition
#' data in an SS operating model. Original data is removed and dummy data is
#' added at the appropriate bin sizes to the SS \code{.dat} file, causing SS to
#' record age or length composition data in the appropriate bins when the
#' operating model is run. Additionally the code will introduce dummy
#' conditional length-at-age or size- (weight or length) at-age data to the
#' \code{.dat} file. For each data type altered, \code{change_bin} will add data
#' in a full factorial manner, working with existing fleets for all years;
#' potentially adding many rows of data. Currently, \code{.dat} files with
#' multiple genders cannot be manipulated with \code{change_bin}. Use
#' \code{\link{sample_lcomp}}, \code{\link{sample_agecomp}}, and
#' \code{\link{sample_calcomp}} to reduce the data. It is not intended for an
#' \pkg{ss3sim} user to use \code{change_bin} directly. Instead
#' \code{change_bin} is called internally by \code{\link{ss3sim_base}} based
#' on arguments to the sampling functions.
#'
#' @param file_in A character value giving the location of an SS \code{.dat}
#'   file to input.
#' @param file_out A character value giving the location of an SS \code{.dat}
#'   file to output.
#' @param type A vector that can take the one or all of the following entries:
#'   \code{"len"}, \code{"age"}, \code{"cal"}, \code{"mla"}, \code{"mwa"}.
#'   \code{type} controls what data structures the function acts on, with
#'   \code{"len"} augmenting the length composition data, \code{"age"}
#'   augmenting the age composition, \code{"cal"} augmenting the conditional age
#'   at length, \code{"mla"} augmenting the mean length at age data, and
#'   \code{"mwa"} augmenting the mean weight at age data. Default is
#'   \code{"len"}.
#' @param bin_vector A named list of vectors. Named elements provide the desired
#'   bin structure for each data \code{type}. If \code{type = "len"} or
#'   \code{type = "age"} \code{bin_vector} should be a vector of new bins. For
#'   other types in \code{bin_vector} the bins are determined from the current
#'   or specified length and age bins. If names are forgotten, list elements
#'   will be named according to the order of entries in \code{type}.
#' @param fleet_dat A named list of vectors giving the desired fleets and years
#'   for each data type. The names of the list elements should correspond to the
#'   \code{type} and each present element should have \code{$years} and
#'   \code{$fleets} giving the vector of desired years and fleets. Named
#'   elements only need to be specified for those required by \code{type}.
#' @param pop_bin A positive real number for the population bin width. This
#'   option only works if \code{"lbin_method"} is set to \code{"2"} in SS3.
#'   Default is \code{pop_bin = NULL} which leaves the original value.
#' @param write_file Should the \code{.dat} file be written? The new \code{.dat}
#'   file will always be returned invisibly by the function. Setting
#'   \code{write_file = FALSE} can be useful for testing. Note that you must
#'   supply a value to the argument \code{file_out}, but this argument can be
#'   set to any arbitrary value (such as \code{NULL}) if \code{write_file =
#'   FALSE}.
#'
#' @details Within the \code{.dat} file, the conditional age-at-length data is
#'   stored in the same matrix as the age composition data. Thus, it is
#'   necessary that the conditional age-at-length data use the same binning
#'   structure as the age composition data. If \code{type = "caa"} and not
#'   \code{type = c("age", "caa")} the function will add conditional
#'   age-at-length using the binning structure of the current \code{.dat} file.
#'   Also note that if \code{type = c("mla", "mwa")} no entries are currently
#'   necessary in the \code{bin_vector}.
#'
#' @importFrom r4ss SS_readdat SS_writedat
#' @export
#' @seealso \code{\link{sample_lcomp}}, \code{\link{sample_agecomp}}
#' @author Ian Taylor, Sean Anderson, Kelli Johnson
#' @examples
#' d <- system.file("extdata", package = "ss3sim")
#' f_in <- paste0(d, "/example-om/data.ss_new")
#' out <- change_bin(f_in, file_out = NULL,
#'   type = c("len", "age", "cal", "mla", "mwa"),
#'   fleet_dat = list(
#'     "len" = list(years = list(1:3, 1:3), fleets = 1:2),
#'     "age" = list(years = list(1:3, 1:3), fleets = 1:2),
#'     "cal" = list(years = list(1:3, 1:3), fleets = 1:2),
#'     "mla" = list(years = list(1:3, 1:3), fleets = 1:2),
#'     "mwa" = list(years = list(1:3, 1:3), fleets = 1:2)),
#'   bin_vector = list(
#'     "len" = seq(2, 8, 2),
#'     "age" = seq(2, 8, 2)),
#'   write_file = FALSE)
#' print(out$agebin_vector)
#' print(tail(out$agecomp))
#' print(head(out$MeanSize_at_Age_obs))

change_bin <- function(file_in, file_out,
  type = "len",
  bin_vector = NULL,
  pop_bin = NULL,
  fleet_dat = NULL,
  write_file = TRUE) {

  type <- match.arg(type, choices = c("len", "age", "cal", "mla", "mwa"),
    several.ok = TRUE)
  datfile <- SS_readdat(file = file_in, verbose = FALSE)

  if (is.null(fleet_dat)) stop("fleet_dat must be specified")

  # Check .dat file
  if (!file.exists(file_in)) {
    stop(paste(file_in, "was not found while running change_e"))
  }
  if (datfile$Ngenders > 1) {
    stop(paste("_Ngenders is greater than 1 in the operating model.",
      "change_bin only works with single-gender models."))
  }
  if (datfile$lbin_method != 2 & !is.null(pop_bin)) {
    stop(paste("the current model doesn't support a change in 'pop_bin' with a",
      "lbin_method different than option 2"))
  }

  # Check for a vector for every type
  if("len" %in% type) {
    test <- try(bin_vector[["len"]], silent = TRUE)
    if(class(test) == "try-error" | is.null(bin_vector[["len"]])) {
      bin_vector[["len"]] <- datfile$lbin_vector
    }
  }
  if("age" %in% type) {
    test <- try(bin_vector[["age"]], silent = TRUE)
    if(class(test) == "try-error" | is.null(bin_vector[["age"]])) {
      bin_vector[["age"]] <- datfile$agebin_vector
    }
  }
  if (any(c("mla", "mwa") %in% type)) {
    for(i in grep("m", type)){
      bin_vector[[type[i]]] <- datfile$agebin_vector
    }
  }
  if ("cal" %in% type) {
    bin_vector[["cal"]] <- datfile$lbin_vector
  }

  # bin_vector names in same order as type, if it's not named
  if (is.null(names(bin_vector))) {
    names(bin_vector) <- type[seq(length(bin_vector))]
  }
  if (any(names(bin_vector) == "")){
    need <- which(names(bin_vector) == "")
    names(bin_vector)[need] <- type[need]
  }
  if ("age" %in% type){
    if(rev(bin_vector$age)[1] > datfile$Nages){
      stop("bin_vector for ages in change_bin extends beyond population ages")
    }
  }

  # if bin_vector is NULL for length or age then need to use .dat version
  if (!any(vapply(bin_vector, is.numeric, logical(1L))))
    stop("bin_vector must be numeric")
  # Augment age and length fleets and years from conditional matrices
  bin_info <- get_bin_info(dat = fleet_dat)
  if("cal" %in% bin_info$type) {
    fleet_dat$age$fleets <- with(bin_info, unique(c(fleet[type %in% c("age", "cal")])))
    fleet_dat$len$fleets <- with(bin_info, unique(c(fleet[type %in% c("len", "cal")])))
    fleet_dat$age$years <- lapply(fleet_dat$age$fleets, function(x) {
      with(bin_info, unique(c(year[fleet == x & type %in% c("age", "cal")])))
    })
    fleet_dat$len$years <- lapply(fleet_dat$age$fleets, function(x) {
      with(bin_info, unique(c(year[fleet == x & type %in% c("len", "cal")])))
    })
    fleet_dat$len$Nsamp <- mapply(rep, 1, lapply(fleet_dat$len$years, length))
    fleet_dat$age$Nsamp <- mapply(rep, 1, lapply(fleet_dat$age$years, length))
  }
  bin_info <- get_bin_info(dat = fleet_dat)
  if("mla" %in% bin_info$type){
    fleet_dat$age$fleets <- with(bin_info,
      unique(c(fleet[type == "mla" | type == "age"])))
    fleet_dat$age$years <- lapply(fleet_dat$age$fleets, function(x) {
      with(bin_info, unique(c(year[fleet == x & type %in% c("mla", "age")])))
    })
    fleet_dat$age$Nsamp <- mapply(rep, 1, lapply(fleet_dat$age$years, length))
  }
  bin_info <- get_bin_info(dat = fleet_dat)
  if("mwa" %in% bin_info$type){
    fleet_dat$age$fleets <- with(bin_info,
      unique(c(fleet[type == "mwa" | type == "age"])))
    fleet_dat$age$years <- lapply(fleet_dat$age$fleets, function(x) {
      with(bin_info, unique(c(year[fleet == x & type %in% c("mwa", "age")])))
    })
    fleet_dat$age$Nsamp <- mapply(rep, 1, lapply(fleet_dat$age$years, length))
  }

  ##

  # First generate dummy fleet data for all routines:
  dummy <- make_fleet_dat(fleet_dat)

  # Then create the dummy binning data for each type:
  dummy.data <- lapply(bin_vector, function(x) {
    goodnames <- data.frame("types" = c("len", "age", "cal", "mla", "mwa"),
      "create" = c("l", "a", "a", "f", "f"),
      stringsAsFactors = FALSE)
    partname <- eval.parent(quote(names(X)))[substitute(x)[[3]]]
    newname <- goodnames[match(partname, goodnames$types), "create"]
    newdata <- data.frame(matrix(1, nrow = nrow(dummy[[partname]]), ncol = length(x)))
    names(newdata) <- paste0(newname, x)
    if (grepl("m", partname)) {
      newdata <- cbind(newdata, setNames(newdata, gsub("f", "N_f", names(newdata))))
    }
    newdata
  })

  # TODO: look at making pop_bin of length two with the first argument
  # pertaining to the number of length population bins and the second argument
  # pertaining to the age population bins. The ageing error matrices must also
  # be changed because they have one column per population length bin
  if (length(pop_bin) != 1 & !is.null(pop_bin)) {
    stop("pop bin should be a real number")
  }
  if (!is.null(pop_bin)) datfile$binwidth <- pop_bin

  # Now build the main data matrices:
  if ("len" %in% type) {
    datfile$lbin_vector <- bin_vector$len
    datfile$N_lbins <- length(datfile$lbin_vector)
    datfile$lencomp <- cbind(dummy[["len"]], dummy.data$len)
    datfile$N_lencomp <- nrow(datfile$lencomp)
  }
  if ("age" %in% type) {
    datfile$agebin_vector <- bin_vector$age
    datfile$N_agebins <- length(datfile$agebin_vector)
    datfile$agecomp <- data.frame(dummy[["age"]], "Lbin_lo" = -1,
      "Lbin_hi" = -1, "Nsamp" = 1, dummy.data$age)
    datfile$N_agecomp <- nrow(datfile$agecomp)
  }
  if ("cal" %in% type) {
    binvals <- data.frame(
      "Lbin_lo" = rep(seq_along(datfile$lbin_vector), each = nrow(dummy[["cal"]])),
      "Lbin_hi" = rep(seq_along(datfile$lbin_vector), each = nrow(dummy[["cal"]])))
    caldummy <- do.call("rbind",
      replicate(length(datfile$lbin_vector), dummy[["cal"]], simplify = FALSE))
    dummy.data$cal <- data.frame(matrix(1, ncol = datfile$N_agebins,
      nrow = nrow(caldummy)))
    # add new data frame below existing age data
    datfile$agecomp <- rbind(datfile$agecomp,
      setNames(cbind(data.frame(caldummy, "Lbin_lo" = binvals$Lbin_lo,
        "Lbin_hi" = binvals$Lbin_hi, "Nsamp" = 1), dummy.data$cal),
        names(datfile$agecomp)))
    datfile$N_agecomp <- nrow(datfile$agecomp)
  }
  if (any(c("mla", "mwa") %in% type)) {
    # TODO: SA to KJ: what to do with dummy data here?
    # note that I've just arbitrarily chosen "mla" type here for dummy
    if ("mla" %in% type){
      mdummy <- data.frame(dummy[["mla"]], "Ignore" = 1000)
      mdummy$AgeErr <- 1
      mdummy <- cbind(mdummy, dummy.data$mla)
    }
    if ("mwa" %in% type){
      mwdummy <- data.frame(dummy[["mwa"]], "Ignore" = 1000)
      mwdummy$AgeErr <- -1
      mwdummy <- cbind(mwdummy, dummy.data$mwa)
    }
    if (all(c("mla", "mwa") %in% type)) {
      mdummy <- rbind(mdummy, mwdummy)
    }
    datfile$MeanSize_at_Age_obs <- mdummy
    datfile$N_MeanSize_at_Age_obs <- nrow(datfile$MeanSize_at_Age_obs)
  }

  if (write_file) {
    SS_writedat(datlist = datfile, outfile = file_out, overwrite = TRUE,
      verbose = FALSE)
  }

  invisible(datfile)
}

make_fleet_dat <- function(fleet_dat) {
  # remove any that were passed as NULL:
  # (ss3sim_base() will pass them like this)
  dat <- fleet_dat[!vapply(fleet_dat, is.null, logical(1L))]
  # expand dummy data across all types:
  dummy_dat_list <- lapply(seq_along(dat), function(type) {
    do.call("rbind",
      lapply(seq_along(dat[[type]]$fleets), function(fleet) {
        data.frame(
          "Year"   = dat[[type]]$years[[fleet]],
          "Season" = 1,
          "Fleet"  = dat[[type]]$fleets[fleet],
          "Gender" = 0,
          "Part"   = 0,
          "AgeErr" = 1,
          stringsAsFactors = FALSE)}
      ))
  })
  setNames(dummy_dat_list, names(dat))
}
