#!/usr/bin/Rscript

options(show.error.messages = F, 
        error = function() {
                  cat(geterrmessage(), file = stderr())
                  q("no", 1, F) } )
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")
library("getopt")

options(stringAsfactors = FALSE, useFancyQuotes = FALSE)
options(warn = -1)
args <- commandArgs(trailingOnly = TRUE)
option_specification <- matrix(c(
 "tool_directory",                       "a", 1, "character"
,"tabular_file",                         "b", 1, "character"
,"replication_vector_column_index",      "c", 1, "integer"
,"genotype_vector_column_index",         "d", 1, "integer"
,"first_y_vector_column_index",          "e", 1, "integer"
,"last_y_vector_column_index",           "f", 1, "integer"
,"design",                               "g", 1, "character"
,"block_vector_column_index",            "h", 1, "integer"
,"summarize_by",                         "i", 1, "character"
,"summarize_by_vector_column_index",     "j", 1, "integer"
,"group_variable_1",                     "k", 1, "character"
,"group_variable_1_vector_column_index", "l", 1, "integer"
,"group_variable_2",                     "m", 1, "character"
,"group_variable_2_vector_column_index", "n", 1, "integer"
,"output_file_path",                     "o", 1, "character"
), byrow = TRUE, ncol = 4)
options <- getopt(option_specification)

cat("\nTool Directory: ", options$tool_directory)
cat("\nTabular File: ", options$tabular_file)
cat("\nReplication Vector Column Index: ", options$replication_vector_column_index)
cat("\nGenotype Vector Column Index: ", options$genotype_vector_column_index)
cat("\nFirst Y Vector Column Index: ", options$first_y_vector_column_index)
cat("\nLast Y Vector Column Index: ", options$last_y_vector_column_index)
cat("\nDesign: ", options$design)
cat("\nBlock Vector Column Index: ", options$block_vector_column_index)
cat("\nSummarize By: ", options$summarize_by)
cat("\nSummarize By Vector Column Index: ", options$summarize_by_vector_column_index)
cat("\nGroup Variable #1: ", options$group_variable_1)
cat("\nGroup Variable #1 Vector Column Index: ", options$group_variable_1_vector_column_index)
cat("\nGroup Variable #2: ", options$group_variable_2)
cat("\nGroup Variable #2 Vector Column Index: ", options$group_variable_2_vector_column_index)
cat("\nOutput file path: ", options$output_file_path)
cat("\n\n")

tabular_data <- read.table(file             = options$tabular_file, 
                           header           = TRUE,
                           sep              = "\t", 
                           stringsAsFactors = FALSE, 
                           strip.white      = TRUE, 
                           na.strings       = ".")
#tabular_data

column_names <- colnames(tabular_data)
cat("Column names:\n")
column_names
cat("\n\n")

# Replication 
replication_vector_header <- column_names[options$replication_vector_column_index]
cat("\nreplication vector header: ", replication_vector_header)

# Genotype 
genotype_vector_header <- column_names[options$genotype_vector_column_index]
cat("\ngenotype vector header: ", genotype_vector_header)

# First Y Vector 
cat("\nfirst y vector header: ", column_names[options$first_y_vector_column_index])

# Last Y Vector 
cat("\nlast y vector header: ", column_names[options$last_y_vector_column_index])

# Design 
design <- options$design
cat("\ndesign: ", design)

# Block 
if (design == "rcbd") {
  block_vector_header <- NULL
} else {
  block_vector_header <- column_names[options$block_vector_column_index]
}
cat("\nblock vector header: ", block_vector_header)

# Summarize By 
if (options$summarize_by == "false") {
  summarize_by_vector_header <- NULL
} else {
  summarize_by_vector_header <- column_names[options$summarize_by_vector_column_index]
}
cat("\nsummarize by vector header: ", summarize_by_vector_header)

# Group Variable #1 
if (options$group_variable_1 == "false") {
  group_variable_1_vector_header <- NULL
} else {
  group_variable_1_vector_header <- column_names[options$group_variable_1_vector_column_index]
} 
cat("\ngroup variable 1 vector header: ", group_variable_1_vector_header) 

# Group Variable #2 
if (options$group_variable_2 == "false") {
  group_variable_2_vector_header <- NULL
} else {
  group_variable_2_vector_header <- column_names[options$group_variable_2_vector_column_index]
} 
cat("\ngroup variable 2 vector header: ", group_variable_2_vector_header)

cat("\n\n")

source(paste(options$tool_directory, "/blupcal.R", sep = ""))

fit_all <- data.frame() 

for (y_vector_column_index in options$first_y_vector_column_index:options$last_y_vector_column_index) {
  cat("\ny_vector_column_index: ", y_vector_column_index )
  y_vector_header <- column_names[y_vector_column_index]
  cat("\ny_vector_header: ", y_vector_header)
  cat("\n\n") 
  fit <- blupcal(data        = tabular_data,
                 Replication = replication_vector_header, 
                 Genotype    = genotype_vector_header, 
                 y           = y_vector_header, 
                 design      = design,
                 Block       = block_vector_header, 
                 summarizeby = summarize_by_vector_header, 
                 groupvar1   = group_variable_1_vector_header, 
                 groupvar2   = group_variable_2_vector_header)

  #cat("\n\n") 
  #cat("\nfit: ")
  #cat("\n")
  #fit
  #cat("\n")
  #fit$gid <- as.numeric(levels(fit$gid))[fit$gid]

  if (y_vector_column_index == options$first_y_vector_column_index) { 
    if (options$summarize_by == "false") {
      fit_all <- fit 
    } else {
      fit_all <- fit[c(1, 7, 2, 3, 4, 5, 6)]
    }
  } else {
    if (options$summarize_by == "false") {
      fit_all <- merge(fit_all, fit, "gid") 
    } else {
      fit_all <- merge(fit_all, fit[c(1, 2, 3, 4, 5, 6)], "gid") 
    }
  }
}

formatted_table <- lapply(fit_all, function(.col) {
                                      if (is.numeric(.col)) { 
                                        return(as.numeric(sprintf("%.3f", .col))) 
                                      } else { 
                                        return(.col)
                                      }
                                    })
 
output_file_path <- options$output_file_path
write.table(formatted_table,
            file = output_file_path, 
            sep = "\t",
            row.names = FALSE, 
            quote = FALSE)
