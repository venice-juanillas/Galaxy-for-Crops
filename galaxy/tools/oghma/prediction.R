########################################################
#
# creation date : 26/01/16
# last modification : 26/01/16
# author : Dr Nicolas Beaume
# owner : IRRI
#
########################################################
log <- file(paste(getwd(), "log_prediction.txt", sep="/"), open = "wt")
sink(file = log, type="message")

library(rrBLUP)
library(randomForest)
library(e1071)
library(glmnet)
library(methods)
############################ helper functions #######################

################################## main function ###########################


############################ main #############################
# running from terminal (supposing the OghmaGalaxy/bin directory is in your path) :
# predict.sh -i genotype_file -m model_file -n name -o path_to_result_directory 
## -i : path to the file that contains the genotypes.
# please note that the table must be called "genotype" when your datafile is saved into .rda (automatic if encode.R is used)

## -m : model build through any methods
# please note that the table must be called "model" when your datafile is saved into .rda
# (automatic if classifiers from this pipeline were used)

## -n : prefix of the names of all result files

## -o : path to the directory where the evaluation results are stored.

classifierNames <- c("list", "randomForest", "svm", "cv.glmnet")
cmd <- commandArgs(trailingOnly = T)
source(cmd[1])
# load data
con = file(genotype)
genotype <- readLines(con = con, n = 1, ok=T)
close(con)
genotype <- read.table(genotype, sep="\t", h=T)
colN <- rownames(genotype)
rowN <- colnames(genotype)
genotype <- t(genotype)
rownames(genotype) <- rowN
colnames(genotype) <- colN
con = file(model)
model <- readLines(con = con, n = 1, ok=T)
close(con)
model <- readRDS(model)
# check if the classifier name is valid
if(is.na(match(class(model), classifierNames))) {
  stop(paste(class(model), "is not recognized as a valid model. Valid models are : ", classifierNames))
}
# run prediction according to the classifier
if(class(model) == "list") {
  predictions <- as.matrix(genotype) %*% as.matrix(model$u)
  predictions <- predictions[,1]+model$beta
  predictions <- data.frame(lines=rownames(genotype), predictions=predictions)
} else if(class(model) == "cv.glmnet") {
  predictions <- predict(model, as.matrix(genotype), type = "response")
  predictions <- data.frame(lines=rownames(predictions), predictions=predictions)
} else {
  predictions <- predict(model, genotype)
  predictions <- data.frame(lines=names(predictions), predictions=predictions)
}
# save results
write.table(predictions, file=out, sep="\t", row.names = F)

