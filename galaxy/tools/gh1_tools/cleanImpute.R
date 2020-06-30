#!/usr/bin/env Rscript

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))


option_list <- list()

option_list$fileIn <- make_option('--fileIn', type='character')
option_list$IDsFile <- make_option('--IDsFile', type='character')
option_list$mapFile <- make_option('--mapFile', type='character')
option_list$thresholdNA <- make_option('--thresholdNA', type='numeric')
option_list$thresholdMAF <- make_option('--thresholdMAF', type='numeric')
option_list$outputFile1 <- make_option('--outputFile1', type='character')
option_list$outputFile2 <- make_option('--outputFile2', type='character')


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
do.call(cleanImpute, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
