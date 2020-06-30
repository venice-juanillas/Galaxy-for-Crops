#!/usr/bin/env Rscript

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))


option_list <- list()

option_list$relmat <- make_option('--relmat', type='character')
option_list$targetId <- make_option('--targetId', type='character')
option_list$candId <- make_option('--candId', type='character')
option_list$nchoose <- make_option('--nchoose', type='numeric')
option_list$herit <- make_option('--herit', type='numeric')
option_list$ntry <- make_option('--ntry', type='numeric')
option_list$nrep <- make_option('--nrep', type='numeric')
option_list$outputfile1 <- make_option('--outputfile1', type='character')
option_list$trace <- make_option('--trace', type='character')


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
do.call(sampleCDmean, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
