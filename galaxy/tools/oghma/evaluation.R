
########################################################
#
# creation date : 08/01/16
# last modification : 23/06/16
# author : Dr Nicolas Beaume
# owner : IRRI
#
########################################################

log <- file(paste(getwd(), "log_evaluation.txt", sep="/"), open = "wt")
sink(file = log, type="message")

library("pROC")
library("randomForest")
library("miscTools")

predictionCorrelation <- function(prediction, obs) {
  return(cor(prediction, obs, method = "pearson"))
}

r2.plot <- function(true, predicted, scatterplot=T) {
  if(scatterplot) {
    plot(true, predicted, xlab="trait value", ylab="predicted value", main="", pch=16, 
         ylim=c(min(min(true), min(predicted)), max(max(true), max(predicted))))
    lines(true, true, col="red")
  } else {
    plot(true, ylim=c(min(min(true), min(predicted)), max(max(true), max(predicted))), 
         xlab="individual index", ylab="traitValue", type="l", main="")
    lines(predicted, col="red")
    legend("topright", legend = c("pedicted", "traitValue"), col = c("red", "black"), lty=c(1,1))
  }
}

################################## main function ###########################

evaluatePredictions <- function(data, prediction=NULL, traitValue=NULL, r2=F, 
                                prefix="data", folds=NULL, classes=NULL, cor=F, path=".") {
  eval <- NULL
  if(r2) {
    eval <- c(eval, list(r2=NULL))
  }
  if(cor) {
    eval <- c(eval, list(cor=NULL))
  }
  for (i in 1:length(folds)) {
    train <- unlist(folds[-i])
    test <- folds[[i]]
    if(r2) {
      if(!is.null(traitValue)) {
        jpeg(paste(path, "/", prefix,"fold_",i,"_scatterPlot.jpeg", sep=""))
        eval$r2 <- c(eval$r2, rSquared(traitValue[test], (traitValue[test] - prediction[[i]]))[1,1])
        r2.plot(traitValue[test], prediction[[i]])
        dev.off()
      } else {
        eval$r2 <- c(eval$r2, NA)
      }
    }
    if(cor) {
      if(!is.null(traitValue)) {
        eval$cor <- c(eval$cor, cor(traitValue[test], prediction[[i]]))
      } else {
        eval$cor <- c(eval$cor, NA)
      }
    }
  }
  print(eval)
  write.table(eval, file = paste(path,"/",prefix,"_evaluation.csv", sep=""), sep="\t", row.names = F)
}
############################ main #############################
# evaluation.sh -i path_to_data -p prediction -f folds -t phenotype -r -c -a -n name -o path_to_result_directory 
## -i : path to the file that contains the genotypes.
# please note that the table must be called "encoded" when your datafile is saved into .rda (automatic if encode.R is used)

## -p : prediction made through any methods
# please note that the table must be called "prediction" when your datafile is saved into .rda
# (automatic if prediction methods from this pipeline were used)

## -f : index of the folds to which belong each individual
# please note that the list must be called "folds" (automatic if folds.R was used)

## -t : phenotype of each individual
# please note that the table must be called "phenotype" when your datafile is saved into .rda (automatic if loadGenotype.R was used)

## -r : flag to run a R2 evaluation

## -c : flag to run a correlation evaluation

## -n : prefix of the names of all result files

## -o : path to the directory where the evaluation results are stored.
cmd <- commandArgs(trailingOnly = T)
source(cmd[1])
# set which evaluation are used
if(as.integer(r2) == 1) {
  r2 <- T
}
if(as.integer(cor) == 1) {
  cor <- T
}
# load genotype & phenotype
con = file(genotype)
genotype <- readLines(con = con, n = 1, ok=T)
close(con)
genotype <- t(read.table(genotype, sep="\t",h=T))
phenotype <- read.table(phenotype, sep="\t",h=T)[,1]
# load prediction
con = file(prediction)
prediction <- readLines(con = con, n = 1, ok=T)
close(con)
prediction <- readRDS(prediction)
# load folds
con = file(folds)
folds <- readLines(con = con, n = 1, ok=T)
close(con)
folds <- readRDS(folds)
evaluatePredictions(data=genotype, prediction=prediction, traitValue=phenotype, r2=r2, 
                    prefix=name, folds=folds, cor=cor, path=out)