#!/usr/bin/env Rscript

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))


option_list <- list()

option_list$wE <- make_option('--wE', type='logical')
option_list$wL <- make_option('--wL', type='logical')
option_list$wW <- make_option('--wW', type='logical')
option_list$wG <- make_option('--wG', type='logical')
option_list$wGE <- make_option('--wGE', type='logical')
option_list$wGW <- make_option('--wGW', type='logical')
option_list$data <- make_option('--data', type='character')
option_list$numC <- make_option('--numC', type='integer')
option_list$kinship <- make_option('--kinship', type='character')
option_list$omega <- make_option('--omega', type='character')
option_list$nIter <- make_option('--nIter', type='integer')
option_list$burnIn <- make_option('--burnIn', type='integer')
option_list$thinI <- make_option('--thinI', type='integer')
option_list$report <- make_option('--report', type='character')
option_list$plotfile <- make_option('--plotfile', type='character')


opt <- parse_args(OptionParser(option_list=option_list))

suppressPackageStartupMessages(library(Hackathon2))

## function body not needed here, it is in package

params <- list()
for(param in names(opt))
{
    if (!param == "help")
        params[param] <- opt[param]
}

setClass("GalaxyRemoteError", contains="character")
wrappedFunction <- function(f)
{
    tryCatch(do.call(f, params),
        error=function(e) new("GalaxyRemoteError", conditionMessage(e)))
}


suppressPackageStartupMessages(library(RGalaxy))
do.call(ReactionNorm, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
