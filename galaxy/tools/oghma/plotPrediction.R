########################################################
#
# creation date : 07/06/16
# last modification : 07/06/16
# author : Dr Nicolas Beaume
# owner : IRRI
#
########################################################

log <- file(paste(getwd(), "log_computeR2.txt", sep="/"), open = "wt")
sink(file = log, type="message")

library("miscTools")
library(randomForest)
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

eval <- function(geno, folds, phenotype) {
  r2 <- NULL
  labelIndex <- match("label", colnames(geno))
  for (i in 1:length(folds)) {
    train <- unlist(folds[-i])
    test <- folds[[i]]
    rf <- randomForest(x=geno[train,-labelIndex], y=geno[train,"label"])
    pred <- predict(rf, geno[test,-labelIndex])
   r2 <- c(r2, rSquared(phenotype[test], (phenotype[test] - pred))[1,1])
  }
  return(r2)
}

createFolds <- function(nbObs, n) {
  index <- sample(1:n, size=nbObs, replace = T)
  folds <- NULL
  for(i in 1:n) {
    folds <- c(folds, list(which(index==i)))
  }
  return(folds)
}

############################ main #############################
cmd <- commandArgs(trailingOnly = T)
source(cmd[1])
phenotype <- read.table(phenotype, sep="\t", h=T)[,1] 
predicted <- read.table(predicted, sep = "\t", h=T)[,2]
pdf(out)
r2.plot(phenotype, predicted = predicted, scatterplot = T)
dev.off()