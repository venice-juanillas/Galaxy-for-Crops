customCVMain <- function(g.in      = X, # A n x m genotype matrix (coded as -1, 0, 1), with the row.names of g.in equal to the line names
                         y.in      = Y, # A n x t matrix of phenotypes, with the row.names of y.in equal to the line names, numeric only (no line names in the vector)
                         groups    = grp, # A vector containing group membership for cross-validation
                         k.fold    = 10, # The number of "folds" to perfom cross-validation with
                         reps      = 50, # The number of iterations of fractional cross-validation
                         CV.nIter  = 1500, # Number of interations of Gibbs sampling to perform using the Bayesian models
                         CV.burnIn = 500, # Number of CV.nIter to discard before using the remainder to establish the prior distribution for Bayesian methods
                         models    = c("BayesA", "BayesB", "BayesC", "BL", "BRR") # Vector of model names to employ current code does not support RKHS
)
{
  nPhenotypes <- ncol(y.in)
  if (is.na(nPhenotypes)) {
    nPhenotypes <- 1
  }
  phenotype_headers <- colnames(y.in)
  for (i in c(1:nPhenotypes)) {
    if (nPhenotypes == 1) {
      yCv <- as.double(y.in)
    } else {
      yCv <- as.double(y.in[,i])
    }
    for (j in c(1:length(models))) {
      model <- models[j]
      new_column_header <- paste(phenotype_headers[[i]], model, sep = "_")
      for (k in c(1:reps)) {
        new_column_header <- paste(new_column_header, "iteration", k, sep = "_")
        res <- performCVCustom(g.in, 
                               yCv, 
                               groups, 
                               k.fold, 
                               model, 
                               CV.nIter,
                               CV.burnIn)
        names(res) <- c(paste(new_column_header, "observed", sep = "_"),
                        paste(new_column_header, "predicted", sep = "_"))
        if (k == 1) {
          ResultsR <- res
        } else {
          ResultsR <- rbind(ResultsR, res)
        }
      }
      if (j == 1) {
        ResultsM <- ResultsR
      } else {
        ResultsM <- cbind(ResultsM, ResultsR)
      }
    }
    if (i == 1) {
      ResultsT <- ResultsM
    } else {
      ResultsT <- cbind(ResultsT, ResultsM)
    }
  }
 
  return(ResultsT)
}

performCVCustom <- function(g.in, 
                            y.in, 
                            grp, 
                            k.fold, 
                            model, 
                            CV.nIter, 
                            CV.burnIn) {
  ngrps <- max(grp)
  nRecords <- length(y.in)
  #the number of records in each group
  nGrpRecs <- rep(0, ngrps)
  for (g in c(1:ngrps)) {
    for (i in c(1:nRecords)) {
      if (grp[i] == g) {
        nGrpRecs[as.integer(grp[i])] <- nGrpRecs[as.integer(grp[i])] + 1
      }
    }
  }
  
  #outer loop based on group - subset y then perform k-fold cross valiadtion - yvals not in group to NA then k-fold on the rest
  results <- matrix(0, length(y.in), 2)
  results[,1] <- y.in
  for (g in c(1:ngrps)) {
    #randomly splits data for cross validation
    #stores the number of records for each fold
    #subset y
    ygrp <- rep(0, nGrpRecs[g])
    orgIndiciesGrp <- rep(0, nGrpRecs[g])
    Xgrp <- matrix(0, nGrpRecs[g], length(g.in[1,]))
    #loop to subset subset y by current group
    count <- 1
    for (i in c(1:nRecords)) {
      if (grp[i] == g) {
        orgIndiciesGrp[count] <- i
        ygrp[count] <- y.in[i]
        Xgrp[count,] <- g.in[i,]
        count <- count+1
      }
    }
    foldSizes <- rep(0,k.fold)
    size <- floor(nGrpRecs[g] / k.fold)
    #setting the sizes of the folds
    foldSizes[1:(length(foldSizes) - 1)] <- size
    foldSizes[length(foldSizes)] <- length(ygrp) - (length(foldSizes) - 1) * size
    records <- c(1:length(ygrp))
    #randomizing records for assigning fold membership
    randomizeRecords <- sample(records)
    #groups stores which fold each record belongs to
    grouping <- rep(0, length(ygrp))
    current <- 0
    
    for (i in c(1:length(foldSizes))) {
      for (j in c(1:foldSizes[i])) {
        grouping[randomizeRecords[j + current]] <- i            
      }
      current <- current + foldSizes[i]
    }
   
    ETA <- list(list(X = Xgrp,
                     model = model)) 
    #matrix storing predictions and true values
   
    for (i in c(1:k.fold)) {
      ytrain <- ygrp
      for (j in c(1:length(ytrain))) {
        if (grouping[j] == i) {
          ytrain[j] <- NA
        }
      }
      fm <- BGLR(y = ytrain,
                 ETA = ETA,
                 nIter = CV.nIter, 
                 burnIn = CV.burnIn)
      yhat <- fm$yHat
      for (j in c(1:length(ytrain))) {
        if (grouping[j] == i) {
          results[orgIndiciesGrp[j],2] = yhat[j]
        }
      }
    }
  }
  
  return(as.data.frame(results))  
}
