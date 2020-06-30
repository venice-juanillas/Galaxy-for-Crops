########################################################
#
# creation date : 07/01/16
# last modification : 26/01/16
# author : Dr Nicolas Beaume
# owner : IRRI
#
########################################################

log <- file(paste(getwd(), "log_randomForest.txt", sep="/"), open = "wt")
sink(file = log, type="message")

library(randomForest)
#library(pRF)

############################ helper functions #######################

################################## main function ###########################
rfSelection <- function(genotype, folds, ntree=1000, outFile, evaluation=T) {
  # build model
  labelIndex <- match("label", colnames(genotype))
  if(evaluation) {
    prediction <- NULL
    for(i in 1:length(folds)) {
      test <- folds[[i]]
      train <- unlist(folds[-i])
      rf <- randomForest(x=genotype[train,-labelIndex], y=genotype[train,"label"])
      prediction <- c(prediction, list(predict(rf, genotype[test,-labelIndex])))
    }
    saveRDS(prediction, file = paste(outFile, ".rds", sep = ""))
  } else {
    model <- randomForest(x=genotype[,-labelIndex], y=genotype[,"label"])
    saveRDS(model, file = paste(outFile, ".rds", sep = ""))
  }
}


############################ main #############################
# running from terminal (supposing the OghmaGalaxy/bin directory is in your path) :
# randomForest.sh -i path_to_genotype -p phenotype_file -e -f fold_file -o out_file 
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
rfSelection(genotype = data.frame(t(genotype), label=phenotype, check.names = F, stringsAsFactors = F), evaluation = evaluation, out = out, folds = folds)
cat(paste(paste(out, ".rds", sep = ""), "\n", sep=""))
