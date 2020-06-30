#!/usr/bin/Rscript

options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)});
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8");
#install.packages("vcfR");

.libPaths(c("/home/galaxy/R/x86_64-pc-linux-gnu-library/3.2", "/home/galaxy/data/R/x86_64-pc-linux-gnu-library/3.2"))

library("getopt");
#suppressWarnings(library("vcfR"));
suppressPackageStartupMessages(library("vcfR"));

options(stringAsfactors = FALSE, useFancyQuotes = FALSE);
options(warn = -1);
args <- commandArgs(trailingOnly = TRUE);
option_specification = matrix(c(
  'ground_vcf_gz_file', 'l', 1, 'character',
  'test_vcf_gz_file', 'm', 1, 'character',
  'input_vcf_gz_file', 'n', 1, 'character',  
  'csv_file_path', 'q', 1, 'character',
  'out_file_path','r',1, 'character'
), byrow = TRUE, ncol = 4);
options = getopt(option_specification);


#source("/home/galaxy/data/alaine/tools/problem2/validation/imputeValidation.R")

imputeValidataion <- function(groundDataPath, testDataPath, imputedDataPath) {

  # library(vcfR)
  groundTData <- read.vcfR(file = groundDataPath, verbose = FALSE, convertNA = TRUE)  #imputedData <- read.vcfR(file = "pre-test-miss0.3-imputed.vcf.gz", verbose = FALSE, convertNA = TRUE)
  imputedData <- read.vcfR(file = imputedDataPath, verbose = FALSE, convertNA = TRUE)
  inputData <- read.vcfR(file = testDataPath, verbose = FALSE, convertNA = TRUE)

  for (i in (2:ncol(inputData@gt))) {
    temp <- data.frame(input = inputData@gt[,i],
                       ground = groundTData@gt[,i],
                       imputed = imputedData@gt[,i],
                       correct = 0)
    miss <- temp[is.na(temp[,"input"]),]
    miss[,"ground"] <- as.character(gsub("/", "", miss[,"ground"]))
    miss[,"imputed"] <- gsub("\\|","", miss[,"imputed"])
    miss[,"imputed2"] <- as.character(gsub("10","01", miss[,"imputed"]))

    notImputed <- miss[is.na(miss[,"imputed2"]) & !is.na(miss[,"ground"]),]
    imputed <- miss[!is.na(miss[,"imputed2"]) & !is.na(miss[,"ground"]),]
    imputed[imputed[,"imputed2"] == imputed[,"ground"],"correct"] <- 1

    if (i == 2) {
      info <- data.frame(var = colnames(inputData@gt)[i],
                         correctlyImputed = sum(imputed$correct),
                         wronglyImputed = nrow(imputed) - sum(imputed$correct),
                         numImputed = nrow(imputed),
                         noImputation = nrow(notImputed))

    } else {
      info <- rbind(info, data.frame(var = colnames(inputData@gt)[i],
                                     correctlyImputed = sum(imputed$correct),
                                     wronglyImputed = nrow(imputed) - sum(imputed$correct),
                                     numImputed = nrow(imputed),
                                     noImputation = nrow(notImputed)))
    }
    summary <- data.frame(Counts = colSums(info[,2:ncol(info)]))

  }

  return(list(imputationInfo = info, imputeSummary = summary))
}

result <- imputeValidataion(groundDataPath = options$ground_vcf_gz_file, 
                            testDataPath = options$test_vcf_gz_file, 
                            imputedDataPath = options$input_vcf_gz_file) 

csvfilepath <- options$csv_file_path

#write.csv(result, file = paste(options$csv_file_path, sep = "\n"))
#write.csv(result, file = options$csv_file_path)
write.csv(result$imputationInfo, file = csvfilepath, row.names = FALSE)
write.csv(result$imputeSummary, file = options$out_file_path)

