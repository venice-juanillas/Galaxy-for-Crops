#!/usr/bin/env Rscript

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))


option_list <- list()

option_list$beddata2plink <- make_option('--beddata2plink', type='character')
option_list$bimdata2plink <- make_option('--bimdata2plink', type='character')
option_list$famdata2plink <- make_option('--famdata2plink', type='character')
option_list$thresholdParam <- make_option('--thresholdParam', type='numeric')
option_list$duplicatesList <- make_option('--duplicatesList', type='character')
option_list$histogramPlot <- make_option('--histogramPlot', type='character')
option_list$NJIBSPlot <- make_option('--NJIBSPlot', type='character')
option_list$HCIBSPlot <- make_option('--HCIBSPlot', type='character')


opt <- parse_args(OptionParser(option_list=option_list))

suppressPackageStartupMessages(library(GetDuplicate))

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
do.call(FindDuplicates, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
