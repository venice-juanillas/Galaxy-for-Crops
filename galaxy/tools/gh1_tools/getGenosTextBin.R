#!/usr/bin/env Rscript

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))


option_list <- list()

option_list$fileIn <- make_option('--fileIn', type='character')
option_list$skip <- make_option('--skip', type='integer')
option_list$nrows <- make_option('--nrows', type='integer')
option_list$fileOut1 <- make_option('--fileOut1', type='character')
option_list$fileOut2 <- make_option('--fileOut2', type='character')
option_list$fileOut3 <- make_option('--fileOut3', type='character')


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
do.call(getGenosTextBin, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
