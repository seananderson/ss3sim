#' Calculate run time
#'
#' Internal function used by \code{get_results_scenario} to calculate the
#' runtime (in minutes) from a \code{Report.sso} file.
#'
#' @param start_time Vector of characters as read in from the r4ss report file
#' @param end_time Vector of characters as read in from the r4ss report file
#' @author Cole Monnahan

calculate_runtime <- function(start_time, end_time) {
    ## The start_time and end_time strings are complex and need to be cleaned up
    ## before processing into date objects.
  start <- data.frame(do.call(rbind, strsplit(x = as.character(start_time),
    split = " ", fixed = T))[, -(1:2)])
  end <- data.frame(do.call(rbind, strsplit(x = as.character(end_time),
    split = " ", fixed = T))[, -(1:2)])
  start <- as.data.frame(t(start))
  end <- as.data.frame(t(end))
  names(start) <- names(end) <- c("month", "day", "time", "year")
  start.date <- lubridate::ymd_hms(with(start, paste(year,
    month, day, time, sep = "-")))
  end.date <- lubridate::ymd_hms(with(end, paste(year,
    month, day, time, sep = "-")))
  run.mins <- as.vector(end.date - start.date)/60
  return(run.mins)
}

#' Extract SS3 simulation output
#'
#' This high level function extracts results from SS3 model runs. Give it a
#' directory which contains directories for different "scenario" runs, within
#' which are replicates and potentially bias adjustment runs. It writes two
#' data.frames to file: one for single scalar values (e.g. MSY) and a second
#' that contains output for each year of the same model (timeseries, e.g.
#' biomass(year)). These can always be joined later.
#'
#' @param directory The directory which contains scenario folders with
#'   results.
#' @param overwrite_files A switch to determine if existing files should be
#'   overwritten, useful for testing purposes or if new replicates are run.
#' @param user_scenarios A character vector of scenarios that should be read
#'   in. Default is NULL, which indicates find all scenario folders in
#'   \code{directory}
#' @export
#' @return
#' Creates two .csv files in the current working directory:
#' \code{ss3sim_ts.csv} and \code{ss3sim_scalar.csv}.
#' @author Cole Monnahan
#' @family get-results
get_results_all <- function(directory=getwd(), overwrite_files=FALSE,
  user_scenarios=NULL){

    on.exit(setwd(directory))
    ## Get unique scenarios that exist in the folder. Might be other random
    ## stuff in the folder so be careful to extract only scenario folders.
    all.dirs <- list.dirs(path=directory, full.names=FALSE, recursive=FALSE)
    ## To select scenarios that has at least 2 files (1 iteration folder and 1
    ## bias folder) i.e to only examine cases that passed the convergence test
    nb.iter <- sapply(1:length(all.dirs),
      function(x) length(list.files(all.dirs[x])))
    select.dirs <- all.dirs[which(nb.iter>1)]
    temp.dirs <- sapply(1:length(select.dirs), function(i) {
        x <- unlist(strsplit(select.dirs[i], split="/"))
        return(x[length(x)])
    })
    ## Choose whether to do all scenarios or the vector passed by user
    if(is.null(user_scenarios)) {
        scenarios <- temp.dirs[substr_r(temp.dirs,4) %in% c("-cod", "-fla","-sar")]
    } else {
        scenarios <- user_scenarios
    }

    if(length(scenarios)==0)
        stop(paste("Error: No scenarios found in:",directory))
    message(paste("Extracting results from", length(scenarios), "scenarios"))

    ## Loop through each scenario in folder
    ts.list <- scalar.list <- list()
    for(i in 1:length(scenarios)){
        setwd(directory)
        scen <- scenarios[i]
        ## If the files already exist just read them in, otherwise get results
        scalar.file <- paste0(scen,"/results_scalar_",scen,".csv")
        ts.file <- paste0(scen,"/results_ts_",scen,".csv")
        ## Delete them if this is flagged on
        if( overwrite_files){
            if(file.exists(scalar.file)) file.remove(scalar.file)
            if(file.exists(ts.file)) file.remove(ts.file)
            get_results_scenario(scenario=scen, directory=directory,
                                 overwrite_files=overwrite_files)
        }
        ## Check if still there and skip if already so, otherwise read in
        ## and save to file
        else if(!file.exists(scalar.file) |  !file.exists(ts.file)){
            get_results_scenario(scenario=scen, directory=directory,
                                 overwrite_files=overwrite_files)
        }
        scalar.list[[i]] <- read.csv(scalar.file)
        ts.list[[i]] <- read.csv(ts.file)
    }
    ## Combine all scenarios together and save into big final files
    scalar.all <- do.call(plyr::rbind.fill, scalar.list)
    scalar.all$ID <- with(scalar.all, paste(scenario, replicate, sep="-"))
    ts.all <- do.call(plyr::rbind.fill, ts.list)
    ts.all$ID <- with(ts.all, paste(scenario, replicate, sep="-"))
    write.csv(scalar.all, file="ss3sim_scalar.csv")
    write.csv(ts.all, file="ss3sim_ts.csv")
    message(paste("Final result files written to", directory))
}

#' Extract SS3 simulation results for one scenario.
#'
#' Function that extracts results from all replicates inside a supplied
#' scenario folder. The function writes 3 .csv files to the scenario folder:
#' (1) scalar metrics with one value per replicate (e.g. $R_0$, $h$), (2) a
#' timeseries data ('ts') which contains multiple values per replicate (e.g.
#' $SSB_y$ for a range of years $y$), and (3) residuals on the log scale from
#' the surveys across all replicates (this feature is not fully tested!). The
#' function \code{get_results_all} loops through these .csv files and combines
#' them together into a single "final" dataframe.
#'
#' @param scenario A single character giving the scenario from which to
#'   extract results.
#' @param directory The directory which contains the scenario folder.
#' @param overwrite_files A boolean (default is FALSE) for whether to delete
#'   any files previously created with this function. This is intended to be
#'   used if replicates were added since the last time it was called, or any
#'   changes were made to this function.
#' @author Cole Monnahan
#' @family get-results
#' @export
#' @examples \dontrun{
#' d <- system.file("extdata", package = "ss3sim")
#' case_folder <- paste0(d, "/eg-cases")
#' om <- paste0(d, "/models/cod-om")
#' em <- paste0(d, "/models/cod-em")
#' run_ss3sim(iterations = 1:2, scenarios =
#'   c("D0-E0-F0-G0-R0-S0-M0-cod"),
#'   case_folder = case_folder, om_dir = om, em_dir = em,
#'   bias_adjust = FALSE)
#' get_results_scenario(c("D0-E0-F0-G0-R0-S0-M0-cod"))
#' }
get_results_scenario <- function(scenario, directory=getwd(),
  overwrite_files=FALSE){
    ## This function moves the wd around so make sure to reset on exit,
    ## especially in case of an error
    old_wd <- getwd()
    on.exit(setwd(old_wd))
    if (file.exists(pastef(directory, scenario))) {
      setwd(pastef(directory, scenario))
    } else {
      stop(paste("Scenario", scenario, "does not exist in", directory))
    }
    ## Stop if the files already exist or maybe delete them
    scalar.file <- paste0("results_scalar_",scenario,".csv")
    ts.file <- paste0("results_ts_",scenario,".csv")
    resids.file <- paste0("results_resids_",scenario,".csv")
    if(file.exists(scalar.file) | file.exists(ts.file)){
        if(overwrite_files) {
            ## Delete them and continue
            message(paste0("Files deleted for ", scenario))
            file.remove(scalar.file, ts.file)
        } else {
            ## Stop the progress
            stop(paste0("Files already exist for ", scenario,"
              and overwrite_files=FALSE"))
        }
    }
    ## Check for bias correction for this scenario, grab it if exists otherwise
    ## report NAs
    bias <- rep(NA,7)
    names(bias) <- c("bias1","bias2","bias3","bias4","bias5",
                     "bias.converged","bias.tried")
    if(length(grep("bias", dir()))==1){
        bias[1:5] <- unlist(read.table(file="bias/AvgBias.DAT", header=TRUE))
        bias.file <- read.table(file="bias/AdjustBias.DAT", header=FALSE)
        ## The ones with NAs mean it didn't converge
        bias[6] <- nrow(na.omit(bias.file))
        bias[7] <- nrow(bias.file)
    }

    ## Loop through each replicate, not including the bias folders, and get
    ## results from both models
    ## Remove the .csv files and bias folder, they are not reps
    reps.dirs <- list.files(pattern = "[0-9]+$")
    reps.dirs <- sort(as.numeric(reps.dirs))
    if(length(reps.dirs)==0)
        stop(paste("Error:No replicates for scenario", scenario))
    ## Loop through replicates and extract results using r4ss::SS_output
    resids.list <- list()
    for(rep in reps.dirs){
        ## message(paste0("Starting", scen, "-", rep))
      report.em <- r4ss::SS_output(paste0(rep,"/em/"), covar=FALSE,
        verbose=FALSE,compfile="none", forecast=TRUE, warn=TRUE, readwt=FALSE,
        printstats=FALSE, NoCompOK=TRUE)
      report.om <- r4ss::SS_output(paste0(rep,"/om/"), covar=FALSE, verbose=FALSE,
        compfile="none", forecast=FALSE, warn=TRUE, readwt=FALSE,
        printstats=FALSE, NoCompOK=TRUE)
        ## Grab the residuals for the indices
        resids <- log(report.em$cpue$Obs) - log(report.em$cpue$Exp)
        resids.long <- data.frame(report.em$cpue[,c("FleetName", "Yr")], resids)
        resids.list[[rep]] <-  cbind(scenario, rep,
          reshape2::dcast(resids.long, FleetName~Yr, value.var="resids"))
        ## Get scalars from the two models
        scalar.om <- get_results_scalar(report.om)
        names(scalar.om) <- paste0(names(scalar.om),"_om")
        scalar.em <- get_results_scalar(report.em)
        names(scalar.em) <- paste0(names(scalar.em),"_em")
        ## Get timeseires from the two
        timeseries.om <- get_results_timeseries(report.om)
        names(timeseries.om) <- paste0(names(timeseries.om),"_om")
        timeseries.em <- get_results_timeseries(report.em)
        names(timeseries.em) <- paste0(names(timeseries.em),"_em")

        ## Combine them together and massage a bit
        scalar <- cbind(scalar.om, scalar.em, t(bias))
        ts <- cbind(timeseries.om, timeseries.em)
        scalar$scenario <- ts$scenario <- scenario
        scalar$replicate <- ts$replicate <- rep
        ## parse the scenarios into columns for plotting later
        scenario.scalar <-
            data.frame(do.call(rbind, strsplit(as.character(scalar$scenario),
                                               "-")), stringsAsFactors=FALSE)
        names(scenario.scalar) <-
            c(substr(as.vector(as.character(
                scenario.scalar[1,-ncol(scenario.scalar)])), 1,1) ,"species")
        scenario.ts <-
            data.frame(do.call(rbind, strsplit(as.character(ts$scenario), "-")),
                       row.names=row.names(ts), stringsAsFactors=FALSE)
        names(scenario.ts) <-
            c(substr(as.vector(as.character(
                scenario.ts[1,-ncol(scenario.ts)])), 1,1) ,"species")

        scalar <- cbind(scalar, scenario.scalar)
        ts <- cbind(ts, scenario.ts)
        ## Other calcs
        ts$year <- ts$Yr_om
        ts$Yr_om <- NULL
        ts$Yr_em <- NULL
        scalar$max_grad <- scalar$max_grad_em
        ignore.cols <- which(names(scalar) %in% c("max_grad_om", "max_grad_em"))
        scalar <- scalar[ , -ignore.cols]

        ## Also get the version and runtime, as checks
        temp <- readLines(con=paste0(rep,"/em/Report.sso"), n=10)
        scalar$version <- temp[1]
        scalar$RunTime <- calculate_runtime(temp[4],temp[5])
        scalar$hessian <- file.exists(paste0(rep,"/em/admodel.cov"))
        ## Write them to file in the scenario folder
        scalar.exists <- file.exists(scalar.file)
        write.table(x=scalar, file=scalar.file, append=scalar.exists,
                    col.names=!scalar.exists, row.names=FALSE, sep=",")
        ts.exists <- file.exists(ts.file)
        write.table(x=ts, file=ts.file, append=ts.exists,
                    col.names=!ts.exists, row.names=FALSE, sep=",")
    }
    ## Create df for the residuals
    resids <- do.call(rbind, resids.list)
    write.table(x=resids, file=resids.file, sep=",", row.names=FALSE)
    ## End of loops for extracting results
    message(paste0("Result files created for ",scenario, " with ",
                 length(reps.dirs), " replicates"))
}

#' Extract time series from a model run.
#'
#' Extract time series from an \code{SS_output} list from a model run.
#' Returns a data.frame of the results for SSB, recruitment and effort by year.
#'
#' @param report.file An \code{SS_output} list for a model (operating model or estimation model).
#' @export
#' @family get-results
#' @author Cole Monnahan
get_results_timeseries <- function(report.file){
    years <- report.file$startyr:(report.file$endyr +
                                  ifelse(is.na(report.file$nforecastyears) ==
                                      TRUE, 0,
                                         report.file$nforecastyears))
    xx <- subset(report.file$timeseries,
                 select=c("Yr","SpawnBio", "Recruit_0", "F:_1"))
    xx <- xx[xx$Yr %in% years,]
    names(xx) <- gsub(":_1","", names(xx))
    ## create final data.frame
    df <- data.frame(xx, row.names=NULL )
    return(invisible(df))
}

#' Extract scalar quantities from a model run.
#'
#' Extract scalar quantities from an \code{SS_output} list from a model run.
#' Returns a data.frame of the results (a single row) which can be rbinded later.
#' @param report.file An SS_output list for a model (operating model or estimation model).
#' @family get-results
#' @export
#' @author Cole Monnahan
get_results_scalar <- function(report.file){
    der <- report.file$derived_quants
    SSB_MSY <-  der[which(der$LABEL=="SSB_MSY"),]$Value
    TotYield_MSY <-  der[which(der$LABEL=="TotYield_MSY"),]$Value
    SSB_Unfished <-  der[which(der$LABEL=="SSB_Unfished"),]$Value
    Catch_endyear <-
        rev(report.file$timeseries[,grep("dead\\(B\\)",
          names(report.file$timeseries))])[1]
    pars <- data.frame(t(report.file$parameters$Value))
    names(pars) <- report.file$parameters$Label
    ## Remove the recruitment devs and efforts as these are in the ts file
    recdev.index <- grep("MAIN_", toupper(names(pars)), fixed=TRUE)
    if(length(recdev.index)>0) pars <- pars[,-recdev.index]
    effort.index <- grep("F_FLEET_", toupper(names(pars)), fixed=TRUE)
    if(length(effort.index)>0) pars <- pars[,-effort.index]
    names(pars) <- gsub("\\(","_", names(pars))
    names(pars) <- gsub("\\)","", names(pars))
    max_grad <- report.file$maximum_gradient_component
    NLL <- report.file$likelihoods_used[1,1]
    depletion <- report.file$current_depletion
    ## get the number of params on bounds from the warning.sso file, useful for
    ## checking convergence issues
    warn <- report.file$warnings
    warn.line <- grep("Number_of_active_parameters", warn, fixed=TRUE)
    params_on_bound <-
        ifelse(length(warn.line)==1,
          as.numeric(strsplit(warn[warn.line], split=":")[[1]][2]), NA)
    ## Combine into final df and return it
    df <- cbind(SSB_MSY, TotYield_MSY, SSB_Unfished, max_grad, depletion,
                NLL, params_on_bound, pars, Catch_endyear)
    return(invisible(df))
}
