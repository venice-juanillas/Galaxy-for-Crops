#!/usr/bin/Rscript

options(show.error.messages = F, error = function(){ cat(geterrmessage(), file = stderr())
                                                     q("no", 1, F) } )
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")
library("getopt")
library("BGLR")

options(stringAsfactors = FALSE, useFancyQuotes = FALSE)
options(warn = -1)
args <- commandArgs(trailingOnly = TRUE)
option_specification <- matrix(c(
 "tool_directory",                      "a", 1, "character"
,"genotypes_file",                      "b", 1, "character"
,"phenotypes_file",                     "c", 1, "character"
,"sample_vector_column_index",          "d", 1, "integer"
,"first_phenotype_vector_column_index", "e", 1, "integer"
,"number_of_phenotypes",                "f", 1, "integer"
,"group_memberships_file",              "g", 1, "character"
,"main_option",                         "h", 1, "character"
,"number_of_kfolds",                    "i", 1, "integer"
,"number_of_iterations",                "j", 1, "integer"
,"number_of_CV_iterations",             "k", 1, "integer"
,"CV_burnIn",                           "l", 1, "integer"
,"models",                              "m", 1, "character"
,"csv_file_path",                       "n", 1, "character"
,"png_file_path",                       "o", 1, "character"
,"pdf_file_path",                       "p", 1, "character"
), byrow = TRUE, ncol = 4)
options <- getopt(option_specification)

cat("\nTool Directory: ", options$tool_directory)
cat("\nGenotype File: ", options$genotypes_file)
cat("\nPhenotype File: ", options$phenotypes_file)
cat("\nSample Vector Column Index: ", options$sample_vector_column_index)
cat("\nFirst Phenotype Vector Column Index", options$first_phenotype_vector_column_index)
cat("\nNumber of Phenotypes", options$number_of_phenotypes)
cat("\nGroup Memberships File: ", options$group_memberships_file)
cat("\nMain Option: ", options$main_option)
cat("\nNumber of K-Folds: ", options$number_of_kfolds)
cat("\nNumber of Iterations: ", options$number_of_iterations)
cat("\nNumber of CV Iterations: ", options$number_of_CV_iterations)
cat("\nCV BurnIn: ", options$CV_burnIn)
cat("\nModels: ", options$models)
cat("\nCSV file path: ", options$csv_file_path)
cat("\nPNG file path: ", options$png_file_path)
cat("\nPDF file path: ", options$pdf_file_path)
cat("\n")

genotypes_data <- apply(read.table(file = options$genotypes_file,
                                   header = TRUE, 
                                   sep = "\t", 
                                   stringsAsFactors = FALSE, 
                                   strip.white = TRUE), 
                        2, 
                        as.numeric)
phenotypes_data_frame <- read.table(file = options$phenotypes_file, 
                                    header = TRUE, 
                                    sep = "\t",
                                    #row.names = options$sample_vector_column_index, 
                                    stringsAsFactors = FALSE, 
                                    strip.white = TRUE)
sample_names <- phenotypes_data_frame[[options$sample_vector_column_index]]
if (options$number_of_phenotypes == 1) {
  chosen_phenotypes_data_frame <- phenotypes_data_frame[c(options$first_phenotype_vector_column_index)]
} else {
  chosen_phenotypes_data_frame <- phenotypes_data_frame[, options$first_phenotype_vector_column_index:(options$first_phenotype_vector_column_index + options$number_of_phenotypes - 1)]
}
phenotypes_data <- apply(chosen_phenotypes_data_frame,
                         2, 
                         as.numeric)
group_memberships_data <- apply(read.table(file = options$group_memberships_file, 
                                           header = TRUE, 
                                           sep = "\t", 
                                           stringsAsFactors = FALSE, 
                                           strip.white = TRUE), 
                                2, 
                                as.numeric)

group_memberships_data <- group_memberships_data[,1] 
group_memberships_data[1] <- 1 
main_option <- options$main_option
number_of_kfolds <- options$number_of_kfolds
number_of_iterations <- options$number_of_iterations
number_of_CV_iterations <- options$number_of_CV_iterations
CV_burnIn <- options$CV_burnIn
models <- c()
for (model in strsplit(options$models, ','))
  models <- c(models, model)
csv_file_path <- options$csv_file_path
png_file_path <- options$png_file_path
pdf_file_path <- options$pdf_file_path

fit <- NULL

if (identical(main_option, "within_groups")) { 
  cat("\nwithin_groups")
  source(paste(options$tool_directory, "/cross_validation_within_groups.R", sep = ""))
  fit = customCVMain(g.in      = genotypes_data, 
                     y.in      = phenotypes_data, 
                     groups    = group_memberships_data, 
                     k.fold    = number_of_kfolds, 
                     reps      = number_of_iterations, 
                     CV.nIter  = number_of_CV_iterations, 
                     CV.burnIn = CV_burnIn, 
                     models    = models)
}
 
if (identical(main_option, "across_groups")) { 
  cat("\nacross_groups")
  source(paste(options$tool_directory, "/cross_validation_across_groups.R", sep = ""))
  fit = customCVMainAcrossGroup(g.in      = genotypes_data, 
                                y.in      = phenotypes_data, 
                                groups    = group_memberships_data, 
                                reps      = number_of_iterations, 
                                CV.nIter  = number_of_CV_iterations, 
                                CV.burnIn = CV_burnIn, 
                                models    = models) 
}

row.names(fit) <- sample_names 


write.csv(fit, 
          file = csv_file_path,
          sep = ",")

if (!(is.null(png_file_path))) {
  png(png_file_path)
  plot(fit)
  dev.off()
}

if (!(is.null(pdf_file_path))) {
  pdf(pdf_file_path)
  plot(fit)
  dev.off()
}
