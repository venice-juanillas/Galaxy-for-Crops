#!/usr/bin/Rscript
options(show.error.messages = F, 
        error = function() { cat(geterrmessage(), file = stderr())
                             q("no", 1, F) } )
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")
library("getopt")
library("BGLR")

options(stringAsfactors = FALSE, 
        useFancyQuotes = FALSE)
options(warn = -1)
args <- commandArgs(trailingOnly = TRUE)
option_specification <- matrix(c(
 "input_phenotypes_file",                "a", 1, "character"
,"sample_name_vector_column_index",      "b", 1, "integer"
,"first_phenotype_vector_column_index",  "c", 1, "integer" 
,"last_phenotype_vector_column_index",   "d", 1, "integer" 
,"response_type",                        "e", 1, "character"
,"lower_bound_vector_column_index",      "f", 1, "integer"
,"upper_bound_vector_column_index",      "g", 1, "integer"
,"eta",                                  "h", 1, "character"
,"incidence_matrix_needs_transposition", "i", 1, "character"
,"weights_vector_column_index",          "j", 1, "integer"
,"number_of_iterations",                 "k", 1, "integer"
,"burnin",                               "l", 1, "integer"
,"thinning",                             "m", 1, "integer"
,"saveat",                               "n", 1, "character"  
,"s0",                                   "o", 2, "character"  
,"df0",                                  "p", 1, "double"  
,"r2",                                   "q", 1, "double"  
,"verbose",                              "r", 1, "logical"  
,"rmexistingfiles",                      "s", 1, "logical"
,"groups_vector_column_index",           "t", 1, "integer"
,"kfold",                                "u", 1, "integer"
,"p_out",                                "v", 1, "integer"
,"name",                                 "z", 1, "character"
,"nrandom",                              "w", 1, "integer"
,"output_file",                          "x", 1, "character"
), byrow = TRUE, ncol = 4)
options <- getopt(option_specification)

cat("\nInput Phenotype(s) File Path: ", options$input_phenotypes_file)
cat("\nSample Name Column Index: ", options$sample_name_vector_column_index)
cat("\nFirst Phentoype Column Index: ", options$first_phenotype_vector_column_index)
cat("\nLast Phenotype Column Index: ", options$last_phenotype_vector_column_index)
cat("\nResponse Type: ", options$response_type)
cat("\nLower Bound (a) Vector Column: ", options$lower_bound_vector_column_index)
cat("\nUpper Bound (b) Vector Column: ", options$upper_bound_vector_column_index)
cat("\nETA: ", options$eta)
cat("\nIncidence Matrix Needs Transposition: ", options$incidence_matrix_needs_transposition)
cat("\nWeights Vector Column: ", options$weights_vector_column_index)
cat("\nNumber of Iterations: ", options$number_of_iterations)
cat("\nBurn-In: ", options$burnin)
cat("\nThinning: ", options$thinning)
cat("\nsaveAt: ", options$saveat)
cat("\nS0: ", options$s0)
cat("\ndf0: ", options$df0)
cat("\nR2: ", options$r2)
cat("\nverbose: ", options$verbose)
cat("\nrmExistingFiles: ", options$rmexistingfiles)
cat("\nGroups Vector Column: ", options$groups_vector_column_index)
cat("\nKFold: ", options$kfold)
cat("\nP_out: ", options$p_out)
cat("\nNRandom: ", options$nrandom)
cat("\nOutput File Path: ", options$output_file)
cat("\nName: ", options$name)
cat("\n\n")

data <- read.table(file        = options$input_phenotypes_file, 
                   header      = TRUE, 
                   sep         = "\t",
                   strip.white = TRUE)
columnNames <- colnames(data)

sample_names <- c(as.character(data[[options$sample_name_vector_column_index]]))

start_column_index <- options$first_phenotype_vector_column_index
end_column_index <- options$last_phenotype_vector_column_index
if (options$first_phenotype_vector_column_index > options$last_phenotype_vector_column_index){
end_column_index <- ncol(data)
}

response_type <- options$response_type
cat("\nresponse_type: ", response_type)

if (options$lower_bound_vector_column_index == "NULL") a <- NULL else a <- c(as.numeric(data[[options$lower_bound_vector_column_index]]))
cat("\na: ")
a

if (options$upper_bound_vector_column_index == "NULL") b <- NULL else b <- c(as.numeric(data[[options$upper_bound_vector_column_index]]))
cat("b: ")
b

etaList <- strsplit(options$eta, ",")
etaSize <- length(etaList[[1]]) / 2
if (etaSize == 0) {
  ETA <- NULL
} else {
  ETA <- list()
  i <- 1
  count <- 1
  while (i <= length(etaList[[1]])) {
    mat <- read.table(etaList[[1]][i], 
                      header      = TRUE, 
                      sep         = "\t",
                      strip.white = TRUE)
    model <- etaList[[1]][i+1]
    if (options$incidence_matrix_needs_transposition == "FALSE") {
      ETA[[count]] <- list(X = assign(paste("X", count, sep = ""), 
                                      as.matrix(mat)), 
                           model = as.character(model)) } else {
      ETA[[count]] <- list(X = assign(paste("X", count, sep = ""), 
                                      t(as.matrix(mat))), 
                           model = as.character(model))
    }
    count <- count + 1
    i <- i + 2
  }
}
#cat("ETA: ")
#ETA

if (options$weights_vector_column_index == "NULL") weights <- NULL else weights <- c(as.numeric(data[[options$weights_vector_column_index]]))
cat("weights: ")
weights

nIter <- options$number_of_iterations
cat("nIter: ", nIter)

burnIn <- options$burnin
cat("\nburnIn: ", burnIn)

thin <- options$thinning
cat("\nthin: ", thin)

saveAt <- options$saveat
cat("\nsaveAt: ", saveAt)

if (options$s0 == "NULL") S0 <- NULL else S0 <- eval(parse(text = options$s0))
cat("\nS0: ")
S0

df0 <- options$df0
cat("df0: ", df0)

R2 <- options$r2
cat("\nR2: ", R2)

verbose <- options$verbose
cat("\nverbose: ", verbose)

rmExistingFiles <- options$rmexistingfiles
cat("\nrmExistingFiles: ", rmExistingFiles)

if (options$groups_vector_column_index == "NULL") groups <- NULL else groups <- c(as.numeric(data[[options$groups_vector_column_index]]))
cat("\ngroups: ", groups)

folds <- options$kfold
p_out <- options$p_out
if (p_out != "NULL") {
  folds <- ceiling(length(c(as.numeric(data[[start_column_index]]))) / p_out)
}
cat("\nfolds: ", folds)
cat("\np_out: ", p_out)

Nrand <- options$nrandom
cat("\nNrand: ", Nrand)

cat("\n\n")

if ((Nrand != "NULL") && (folds != "NULL")) {
  output_data_frame <- data.frame(c(1:Nrand))
  output_data_frame_index <- 1
  if (options$name != "NULL"){
    newname = paste("Randomization Number", options$name, sep = " ")
    names(output_data_frame)[output_data_frame_index] <- newname
  }
  else{
    names(output_data_frame)[output_data_frame_index] <- "Randomization Number" 
  }
  output_data_frame_index <- output_data_frame_index + 1
} else {
  output_data_frame <- data.frame(sample_names)
  output_data_frame_index <- 1
  names(output_data_frame)[output_data_frame_index] <- "Sample Name" 
  output_data_frame_index <- output_data_frame_index + 1
}

for (y_column_index in start_column_index:end_column_index) {
  # each n-th phenotype vector
  y <- c(as.numeric(data[[y_column_index]]))

  if ((Nrand != "NULL") && (folds != "NULL")) {
    predicted <- rep(0, Nrand * length(y))
    estimates <- rep(0, length(y))
    trueValues <- rep(y, Nrand)
    indexes <- c(1:length(y))
    cvNum <- 1
    fs <- floor(length(y) / folds)
    foldsize <- rep(0, folds)
    for (i in c(1:folds)) {
      if (i == folds) {
        foldsize[i] <- length(y) - (i - 1) * foldsize
      } else {
        foldsize[i] <- fs
      }
    }
    correlations_vector <- c()
    for (i in c(1:Nrand))
    { 
      randIndex <- sample(indexes)
      count <- 0
      for (j in c(1:folds)) {
        yt <- y
        yv <- rep(NA, length(y))
        for (k in c(1:foldsize[j])) {
          yt[randIndex[(count + k)]] <- NA
          yv[randIndex[(count + k)]] <- y[randIndex[count + k]]
        }
        fit <- BGLR(y               = yt, 
                    response_type   = response_type, 
                    a               = a, 
                    b               = b, 
                    ETA             = ETA, 
                    weights         = weights, 
                    nIter           = nIter, 
                    burnIn          = burnIn, 
                    thin            = thin, 
                    saveAt          = saveAt, 
                    S0              = S0, 
                    df0             = df0, 
                    R2              = R2, 
                    verbose         = verbose, 
                    rmExistingFiles = rmExistingFiles, 
                    groups          = groups)
        for (k in c(1:foldsize[j])) {
          estimates[randIndex[count + k]] <- fit$yHat[randIndex[count + k]]
        }
        cvNum <- cvNum + 1
        count <- count + foldsize[j]
      }
      correlation <- cor(estimates, y)
      cat("\nCorrelation: ", correlation) 
      correlations_vector <- c(correlations_vector, correlation)
      start <- (i - 1) * length(y) + 1
      stop <- i * length(y)
      predicted[start:stop] <- estimates
    }
    output_data_frame <- cbind(output_data_frame, correlations_vector)
    names(output_data_frame)[output_data_frame_index] <- paste(names(data)[y_column_index], "correlation", sep = "_")
    output_data_frame_index <- output_data_frame_index + 1
    cat("\n\n")
  } else { 
    output_data_frame <- cbind(output_data_frame, y)
    names(output_data_frame)[output_data_frame_index] <- paste(names(data)[y_column_index], "Observed", sep = "_")
    output_data_frame_index <- output_data_frame_index + 1
    fit <- BGLR(y               = y, 
                response_type   = response_type, 
                a               = a, 
                b               = b, 
                ETA             = ETA, 
                weights         = weights, 
                nIter           = nIter, 
                burnIn          = burnIn, 
                thin            = thin, 
                saveAt          = saveAt, 
                S0              = S0, 
                df0             = df0, 
                R2              = R2, 
                verbose         = verbose, 
                rmExistingFiles = rmExistingFiles, 
                groups          = groups)
    output_data_frame <- cbind(output_data_frame, fit$yHat)
    names(output_data_frame)[output_data_frame_index] <- paste(names(data)[y_column_index], "Predicted", sep = "_")
    output_data_frame_index <- output_data_frame_index + 1
  }
}

write.table(lapply(output_data_frame, function(.col) {
                                        if (is.numeric(.col)) return(sprintf("%.3f", .col))
                                        else return(.col)
                                      }), 
            file      = options$output_file,
            sep       = "\t",
            col.names = TRUE,
            row.names = FALSE,
            quote     = FALSE)
