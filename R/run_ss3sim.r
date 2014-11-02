#' Master function to run SS3 simulations
#'
#' This is the main high-level wrapper function for running \pkg{ss3sim}
#' simulations. This function first deals with parsing a scenario ID into case
#' arguments, reads the appropriate case files, and then passes these arguments
#' on to \code{\link{ss3sim_base}} to run a simulation. Alternatively, you might
#' choose to run \code{\link{ss3sim_base}} directly and skip the case-file
#' setup.
#'
#' @param iterations Which iterations to run. A numeric vector. For example
#'   \code{1:100}.
#' @param scenarios Which scenarios to run. A vector of character objects. For
#'   example \code{c("D0-E0-F0-R0-M0-cod", "D1-E0-F0-R0-M0-cod")}. Also, see
#'   \code{\link{expand_scenarios}} for a shortcut to specifying the scenarios.
#'   See \code{\link{get_caseargs}} and the vignette for details on specifying
#'   the scenarios.
#' @param case_folder The folder containing the plain-text case files.
#' @param om_dir The folder containing the SS3 operating model
#'   configuration files.
#' @param em_dir The folder containing the SS3 estimation model
#'   configuration files.
#' @param case_files A named list that relates the case IDs to the files to
#'   return. If you are passing time-varying parameters beyond (or instead of)
#'   natural mortality (M), then you will need to adjust these values to
#'   reflect your scenarios. This argument is passed to
#'   \code{\link{get_caseargs}}. See that function for details and examples of
#'   how to specify this.
#' @template user_recdevs
#' @param parallel A logical argument that controls whether the scenarios are
#'   run in parallel. You will need to register multiple cores first with a
#'   package such as \pkg{doParallel} and have the \pkg{foreach} package
#'   installed. See the example below.
#' @param parallel_iterations Logical. By default \code{parallel = TRUE} will
#'   run scenarios in parallel. If you set \code{parallel = TRUE} and
#'   \code{parallel_iterations = TRUE} then the iterations will be run in
#'   parallel. This would be useful if you were only running one scenario
#'   but you wanted to run it faster.
#' @param ... Anything else to pass to \code{\link{ss3sim_base}}. This could
#'   include \code{bias_adjust} and \code{bias_nsim}. Also, you can pass
#'   additional options to the \code{SS3} command through the argument
#'   \code{admb_options}.

#' @author Sean C. Anderson
#'
#' @details The operating model folder should contain: \code{forecast.ss},
#' \code{yourmodel.ctl}, \code{yourmodel.dat}, \code{ss3.par}, and
#' \code{starter.ss}. The files should be the versions that are returned from an
#' SS run as \code{.ss_new} files. This is important because it creates
#' consistent formatting which many of the functions in this package depend on.
#' Rename the \code{.ss_new} files as listed above (and in all lowercase). The
#' estimation model folder should contain all the same files listed above except
#' the \code{ss3.par} and \code{yourmodel.dat} files, which are unnecessary but
#' can be included if desired. See the vignette for details on modifying an
#' existing \code{SS3} model to run with \pkg{ss3sim}. Alternatively, you might
#' consider modifying one of the built-in model configurations.
#'
#' @return
#' The output will appear in whatever your current \R working directory
#' is. There will be folders named after your scenarios. They will
#' look like this:
#' \itemize{
#' \item \code{D0-E0-F0-M0-R0-cod/bias/1/om}
#' \item \code{D0-E0-F0-M0-R0-cod/bias/1/em}
#' \item \code{D0-E0-F0-M0-R0-cod/bias/2/om}
#' \item ...
#' \item \code{D0-E0-F0-M0-R0-cod/1/om}
#' \item \code{D0-E0-F0-M0-R0-cod/1/em}
#' \item \code{D0-E0-F0-M0-R0-cod/2/om}
#' \item ...
#' }
#'
# An illustration of the input and output file structure
# of an \pkg{ss3sim} simulation:
# \figure{filestructure.png}{An illustration of the input and output file
# structure for an ss3sim simulation.}
#'
#' @seealso \code{\link{ss3sim_base}}, \code{\link{run_ss3model}},
#' \code{\link{run_bias_ss3}}, \code{\link{get_caseargs}},
#' \code{\link{expand_scenarios}}
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a temporary folder for the output and set the working directory:
#' temp_path <- file.path(tempdir(), "ss3sim-example")
#' dir.create(temp_path, showWarnings = FALSE)
#' wd <- getwd()
#' setwd(temp_path)
#'
#' # Find the data in the ss3sim package:
#' d <- system.file("extdata", package = "ss3sim")
#' om <- paste0(d, "/models/cod-om")
#' em <- paste0(d, "/models/cod-em")
#' case_folder <- paste0(d, "/eg-cases")
#'
#' # Without bias adjustment:
#' run_ss3sim(iterations = 1:1, scenarios = "D0-E0-F0-R0-M0-cod",
#'   case_folder = case_folder, om_dir = om, em_dir = em)
#' unlink("D0-E0-F0-R0-M0-cod", recursive = TRUE) # clean up
#'
#' # An example specifying the case files:
#' run_ss3sim(iterations = 1:1, scenarios = "D0-E0-F0-R0-cod",
#'   case_folder = case_folder, om_dir = om, em_dir = em,
#'   case_files = list(F = "F", D = c("index", "lcomp",
#'       "agecomp"), R = "R", E = "E"))
#' unlink("D0-E0-F0-R0-cod", recursive = TRUE) # clean up
#'
#' # With bias adjustment:
#' # (Note that bias_nsim should be bigger, say 5 or 10, but it is set
#' # to 2 here so the example runs faster.)
#' run_ss3sim(iterations = 1:1, scenarios = "D1-E0-F0-R0-M0-cod",
#'   case_folder = case_folder, om_dir = om, em_dir = em,
#'   bias_adjust = TRUE, bias_nsim = 2)
#'
#' # Restarting the previous run using the existing bias-adjustment
#' # output
#' run_ss3sim(iterations = 2:3, scenarios = "D1-E0-F0-R0-M0-cod",
#'   case_folder = case_folder, om_dir = om, em_dir = em,
#'   bias_adjust = FALSE, bias_already_run = TRUE)
#' unlink("D1-E0-F0-R0-M0-cod", recursive = TRUE) # clean up
#'
#' # A run with deterministic process error for model checking:
#' recdevs_det <- matrix(0, nrow = 100, ncol = 20)
#' run_ss3sim(iterations = 1:20, scenarios = "D0-E100-F0-R0-M0-cod",
#'   case_folder = case_folder, om_dir = om, em_dir = em,
#'   bias_adjust = TRUE, bias_nsim = 2, user_recdevs = recdevs_det)
#' unlink("D0-E100-F0-R0-M0-cod", recursive = TRUE) # clean up
#'
#' # An example of a run using parallel processing across 2 cores:
#' require(doParallel)
#' registerDoParallel(cores = 2)
#' require(foreach)
#' getDoParWorkers() # check how many cores are registered
#' run_ss3sim(iterations = 1, scenarios = c("D0-E0-F0-R0-M0-cod",
#'     "D1-E0-F0-R0-M0-cod"), case_folder = case_folder,
#'   om_dir = om, em_dir = em, parallel = TRUE)
#' unlink("D0-E0-F0-R0-M0-cod", recursive = TRUE) # clean up
#' unlink("D1-E0-F0-R0-M0-cod", recursive = TRUE) # clean up
#'
#' # Return to original working directory:
#' setwd(wd)
#' }

run_ss3sim <- function(iterations, scenarios, case_folder,
  om_dir, em_dir,
  case_files =
    list(M = "M", F = "F", D = c("index", "lcomp", "agecomp"), R = "R", E = "E"),
  user_recdevs = NULL, parallel = FALSE, parallel_iterations = FALSE,
  ...) {

  if(parallel) {
    cores <- setup_parallel()
    if(cores == 1) parallel <- FALSE
  }

  if(!is.null(user_recdevs)) {
    if(ncol(user_recdevs) < max(iterations)) {
      stop(paste("The number of columns in user_recdevs is less than the",
        "specified number of iterations."))
    }
  }

  # Get arguments for each scenario:
  arg_list <- lapply(scenarios, function(scenario) {
    a <- get_caseargs(folder = case_folder, scenario = scenario,
      case_files = case_files)
    list(
      scenarios      = scenario,
      user_recdevs   = user_recdevs,
      em_dir         = em_dir,
      om_dir         = om_dir,
      tv_params      = a$tv_params,
      tc_params      = a$tail_compression,
      lc_params      = a$lcomp_constant,
      f_params       = a$F,
      index_params   = a$index,
      lcomp_params   = a$lcomp,
      agecomp_params = a$agecomp,
      calcomp_params = a$calcomp,
      wtatage_params = a$wtatage,
      mlacomp_params = a$mlacomp,
      mwacomp_params = a$mwacomp,
      retro_params   = a$R,
      estim_params   = a$E)
  })

  # Note that inside a foreach loop you pop out of your current
  # environment until you go back into an exported function
  # therefore we need to add subst_r to the .export list
  # for foreach to work on Windows:

  x <- NULL # to satisfy R CMD check in the foreach() call below
  it_ <- NULL # to satisfy R CMD check in the foreach() call below

  if (parallel) {
    if (parallel_iterations) {
      ignore <- lapply(arg_list, function(x) {
        # First run bias-adjustment runs if requested:
        dotdotdot <- list(...) # needed so we can nullify bias arguments
        if ("bias_adjust" %in% names(dotdotdot)) {
          if (dotdotdot$bias_adjust) {
            message("Running bias adjustment sequentially first.")
            do.call("ss3sim_base", c(x, list(iterations = NULL, ...)))
          }
        }
        # Now run regular iterations:
        message("Running iterations in parallel.")
        foreach(it_ = iterations, .packages = "ss3sim",
          .verbose = FALSE, .export = "substr_r") %dopar% {
            dotdotdot$bias_adjust <- NULL
            dotdotdot$bias_already_run <- NULL
            do.call("ss3sim_base",  c(x, list(iterations = it_,
              bias_adjust = FALSE, bias_already_run = TRUE, dotdotdot)))}
      })
    } else {
      message("Running scenarios in parallel.")
      foreach(x = arg_list, .packages = "ss3sim",
        .verbose = FALSE, .export = "substr_r") %dopar% {
          do.call("ss3sim_base", c(x, list(iterations = iterations, ...)))}
    }
  } else {
    message("Running scenarios and iterations sequentially.")
    ignore <- lapply(arg_list, function(x) {
      do.call("ss3sim_base", c(x, list(iterations = iterations, ...)))
    })
    # to understand what we just did, play with this toy code:
    # aa <- list(x = 1:2, y = 3:4)
    # do.call("plot", c(aa, list(pch = 20)))
  }

  message(paste("Completed iterations:", paste(iterations, collapse = ", "),
    "for scenarios:", paste(scenarios, collapse = ", ")))
}
