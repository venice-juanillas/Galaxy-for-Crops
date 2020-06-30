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
,"y_vector_column_index",                "e", 1, "integer"
,"design",                               "f", 1, "character"
,"block_vector_column_index",            "g", 1, "integer"
,"summarize_by",                         "h", 1, "character"
,"summarize_by_vector_column_index",     "i", 1, "integer"
,"group_variable_1",                     "j", 1, "character"
,"group_variable_1_vector_column_index", "k", 1, "integer"
,"group_variable_2",                     "l", 1, "character"
,"group_variable_2_vector_column_index", "m", 1, "integer"
,"output_file_path",                     "n", 1, "character"
,"png_plots_file_path",                  "o", 1, "character"
,"png_histograms_file_path",             "p", 1, "character"
,"pdf_plots_file_path",                  "q", 1, "character"
,"pdf_histograms_file_path",             "r", 1, "character"
), byrow = TRUE, ncol = 4)
options <- getopt(option_specification)

cat("\nTool Directory: ", options$tool_directory)
cat("\nTabular File: ", options$tabular_file)
cat("\nReplication Vector Column Index: ", options$replication_vector_column_index)
cat("\nGenotype Vector Column Index: ", options$genotype_vector_column_index)
cat("\nY Vector Column Index: ", options$y_vector_column_index)
cat("\nDesign: ", options$design)
cat("\nBlock Vector Column Index: ", options$block_vector_column_index)
cat("\nSummarize By: ", options$summarize_by)
cat("\nSummarize By Vector Column Index: ", options$summarize_by_vector_column_index)
cat("\nGroup Variable #1: ", options$group_variable_1)
cat("\nGroup Variable #1 Vector Column Index: ", options$group_variable_1_vector_column_index)
cat("\nGroup Variable #2: ", options$group_variable_2)
cat("\nGroup Variable #2 Vector Column Index: ", options$group_variable_2_vector_column_index)
cat("\nOutput file path: ", options$output_file_path)
cat("\nPNG plots file path: ", options$png_plots_file_path)
cat("\nPNG histograms file path: ", options$png_histograms_file_path)
cat("\nPDF plots file path: ", options$pdf_plots_file_path)
cat("\nPDF histograms file path: ", options$pdf_histograms_file_path)
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

# Y 
y_vector_header <- column_names[options$y_vector_column_index]
cat("\ny vector header: ", y_vector_header)

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

fit <- blupcal(data        = tabular_data,
               Replication = replication_vector_header, 
               Genotype    = genotype_vector_header, 
               y           = y_vector_header, 
               design      = design,
               Block       = block_vector_header, 
               summarizeby = summarize_by_vector_header, 
               groupvar1   = group_variable_1_vector_header, 
               groupvar2   = group_variable_2_vector_header)

cat("\n\n") 

output_file_path <- options$output_file_path

cat("\nfit: ")
cat("\n")
fit
cat("\n")

#fit$gid <- as.numeric(levels(fit$gid))[fit$gid]
if (options$summarize_by == "false") {
  fit_view <- fit
} else {
  fit_view <- fit[c(1, 7, 2, 3, 4, 5, 6)]
}

formatted_table <- lapply(fit_view, function(.col) {
                                      if (is.numeric(.col)) { 
                                        return(as.numeric(sprintf("%.3f", .col))) 
                                      } else { 
                                        return(.col)
                                      }
                                    })
 
write.table(formatted_table,
            file = output_file_path, 
            sep = "\t",
            row.names = FALSE, 
            quote = FALSE)

png_plots_file_path <-options$png_plots_file_path
if (!(is.null(png_plots_file_path))) {
  png(png_plots_file_path)
  plot(fit)
  dev.off()
}

png_histograms_file_path <-options$png_histograms_file_path
if (!(is.null(png_histograms_file_path))) {
  png(png_histograms_file_path)
  plot2.blupcal(fit)
  dev.off()
}

pdf_plots_file_path <-options$pdf_plots_file_path
if (!(is.null(pdf_plots_file_path))) {
  pdf(pdf_plots_file_path)
  plot(fit)
  dev.off()
}

pdf_histograms_file_path <-options$pdf_histograms_file_path
if (!(is.null(pdf_histograms_file_path))) {
  pdf(pdf_histograms_file_path)
  plot2.blupcal(fit)
  dev.off()
} 
