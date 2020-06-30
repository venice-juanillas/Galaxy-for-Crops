########################################################
#
# creation date : 27/06/16
# last modification : 27/06/16
# author : Dr Nicolas Beaume
# owner : IRRI
#
########################################################

log <- file(paste(getwd(), "log_computeR2.txt", sep="/"), open = "wt")
sink(file = log, type="message")

library("miscTools")
library(randomForest)

computeR2 <- function(phenotype, prediction) {
  return(rSquared(phenotype, (phenotype - prediction))[1,1])
}
############################ main #############################
cmd <- commandArgs(trailingOnly = T)
source(cmd[1])
phenotype <- read.table(phenotype, sep="\t", h=T)[,1] 
predicted <- read.table(predicted, sep = "\t", h=T)[,2]
cat(computeR2(phenotype, predicted), file=out)