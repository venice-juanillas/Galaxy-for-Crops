########################################################
#
# creation date : 05/01/16
# last modification : 27/06/16
# author : Dr Nicolas Beaume
# owner : IRRI
#
########################################################

log <- file(paste(getwd(), "log_folds.txt", sep="/"), open = "wt")
sink(file = log, type="message")
############################ helper function ####################
# make a clustering of values and return the class of the initial individual
# used for example to assigne class to continious trait value
determineClasses <- function(response, method="pam", k=-1) {
  response <- na.omit(response)
  if(k<2) {
    k <- getBestK(response, method = method)
  }
  clusters <- NULL
  switch(method, 
         pam={clusters <- getPam(data = response, k = k)$cluster},
         warning(paste(method, "not recognized, please choose among : pam"))
  )
  return(clusters)
}

############################ main function #######################

createFolds <- function(nbObs, n) {
  index <- sample(1:n, size=nbObs, replace = T)
  folds <- NULL
  for(i in 1:n) {
    folds <- c(folds, list(which(index==i)))
  }
  return(folds)
}

############################ main #############################
# running from terminal (supposing the OghmaGalaxy/bin directory is in your path) :
# folds.sh -i path_to_data [-n nfold] -p phenotype_file [-k nb_classes] -o output_file 
## -i : path to the file that contains the genotypes, must be a .rda file (as outputed by loadGenotype.R).
# please note that the table must be called "genotype" when your datafile is saved into .rda (automatic if loadGenotype.R was used)

## -k : [optional] number of classes of phenotype. This information is used to equilibrate the folds
# if omitted, 2 classes are assumed

## -p : file that contains the phenotype must be a .rda file (as outputed by loadGenotype.R).
# please note that the table must be called "phenotype" when your datafile is saved into .rda (automatic if loadGenotype.R was used)

## -n : [optional] number of folds for cross validation. if ommited, n will be setted to 10

## -o : path to the file of encoded genotype. the .rda extension is automatically added
cmd <- commandArgs(trailingOnly = T)
source(cmd[1])
# load data and merge them
con = file(genotype)
genotype <- readLines(con = con, n = 1, ok=T)
close(con)
nObs <- ncol(read.table(genotype, sep="\t", h=T))
folds <- createFolds(nObs, as.numeric(n))
out <- paste(out,".rds",sep="")
saveRDS(folds, file=out)
cat(paste(out, "\n", sep=""))