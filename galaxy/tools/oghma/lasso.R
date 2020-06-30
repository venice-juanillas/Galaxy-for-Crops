########################################################
#
# creation date : 08/03/16
# last modification : 08/03/16
# author : Dr Nicolas Beaume
# owner : Dr Nicolas Beaume
#
########################################################
log <- file(paste(getwd(), "log_LASSO.txt", sep="/"), open = "wt")
sink(file = log, type="message")

library(glmnet)
library(methods)
############################ helper functions #######################

################################## main function ###########################
lassoSelection <- function(genotype, evaluation = T, outFile, folds) {
  labelIndex <- match("label", colnames(genotype))
  if(evaluation) {
    prediction <- NULL
    for(i in 1:length(folds)) {
      test <- folds[[i]]
      train <- unlist(folds[-i])
      lasso.fit <- cv.glmnet(x=as.matrix(genotype[train,-labelIndex]), y=genotype[train,labelIndex], alpha=1)
      prediction <- c(prediction, list(predict(lasso.fit, as.matrix(genotype[test,-labelIndex]), type = "response")))
    }
    saveRDS(prediction, file=paste(outFile,".rds", sep=""))
  } else {
    model <- cv.glmnet(x=as.matrix(genotype[,-labelIndex]), y=genotype[,labelIndex], alpha=1)
    saveRDS(model, file = paste(outFile, ".rds", sep = ""))
  }
}

############################ main #############################
# running from terminal (supposing the OghmaGalaxy/bin directory is in your path) :
# lasso.sh -i path_to_genotype -p phenotype_file -e -f fold_file -o out_file 
## -i : path to the file that contains the genotypes, must be a .rda file (as outputed by loadGenotype).
# please note that the table must be called "encoded" when your datafile is saved into .rda (automatic if encoded.R was used)

## -p : file that contains the phenotype must be a .rda file (as outputed by loadGenotype.R).
# please note that the table must be called "phenotype" when your datafile is saved into .rda (automatic if loadGenotype.R was used)

## -e : do evaluation instead of producing a model

## -f : index of the folds to which belong each individual
# please note that the list must be called "folds" (automatic if folds.R was used)

## -o : path to the output folder and generic name of the analysis. The extension related to each type of
# files are automatically added

cmd <- commandArgs(T)
source(cmd[1])
# check if evaluation is required
evaluation <- F
if(as.integer(doEvaluation) == 1) {
  evaluation <- T
  con = file(folds)
  folds <- readLines(con = con, n = 1, ok=T)
  close(con)
  folds <- readRDS(folds)
}
# load genotype and phenotype
con = file(genotype)
genotype <- readLines(con = con, n = 1, ok=T)
close(con)
genotype <- read.table(genotype, sep="\t", h=T)
# phenotype is written as a table (in columns) but it must be sent as a vector for mixed.solve
phenotype <- read.table(phenotype, sep="\t", h=T)[,1] 
# run !
lassoSelection(genotype = data.frame(t(genotype), label=phenotype, check.names = F, stringsAsFactors = F), evaluation = evaluation, outFile = out, folds = folds)
cat(paste(paste(out, ".rds", sep = ""), "\n", sep=""))
