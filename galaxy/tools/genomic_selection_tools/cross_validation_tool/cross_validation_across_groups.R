customCVMainAcrossGroup <- function(g.in      = X, # A n x m genotype matrix (coded as -1, 0, 1), with the row.names of g.in equal to the line names
                                    y.in      = Y, # A n x t matrix of phenotypes, with the row.names of y.in equal to the line names, numeric only (no line names in the vector)
                                    groups    = grp, # A vector containing group membership for cross-validation
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
      for (k in c(1:reps)) {
        res <- performCVCustomAcrossGroups(g.in,
                                           yCv,
                                           groups,
                                           model,
                                           CV.nIter,
                                           CV.burnIn)
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

performCVCustomAcrossGroups <- function(g.in, 
                                        y.in, 
                                        grp,
                                        model, 
                                        CV.nIter, 
                                        CV.burnIn) {
  ngrps <- max(grp)
  nRecords <- length(y.in)
  #the number of records in each group
  cat("\nRecords:\n", length(y.in));
 
  #outer loop based on group - subset y then perform k-fold cross valiadtion - yvals not in group to NA then k-fold on the rest
  results <- matrix(0, length(y.in), 2)
  results[,1] <- y.in
 
  ETA <- list(list(X = g.in,
                   model = model))
  for (g in c(1:ngrps)) {
    #splits data by groups records in each group predicted by other groups
    ytrain <- y.in
    for (i in c(1:nRecords)) {
      if (grp[i] == g) {
        ytrain[i] <- NA
      }
    }

    fm <- BGLR(y = ytrain,
               ETA = ETA,
               nIter = CV.nIter, 
               burnIn = CV.burnIn)
    yhat <- fm$yHat
      
    for (j in c(1:length(ytrain))) {
      if (grp[j] == g) {
        results[j, 2] <- yhat[j]
      }
    }
  }
  
  return(as.data.frame(results))
}
