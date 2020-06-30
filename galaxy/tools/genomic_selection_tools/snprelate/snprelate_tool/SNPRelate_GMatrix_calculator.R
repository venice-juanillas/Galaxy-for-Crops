#!/usr/bin/Rscript
options(show.error.messages = F,
        error = function() { cat(geterrmessage(), file = stderr())
                             q("no", 1, F) } )
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")
library("getopt")
library("gdsfmt")
suppressPackageStartupMessages(library("SNPRelate"))
library("parallel")

options(stringAsfactors = FALSE,
        useFancyQuotes = FALSE)
options(warn = -1)
args <- commandArgs(trailingOnly = TRUE)
option_specification <- matrix(c(
 "tool_directory",        "a", 1, "character"
,"genotypes_file",        "b", 1, "character"
,"autosome_only",         "c", 1, "character"
,"remove_monosnp",        "d", 1, "character"
,"maf",                   "e", 1, "double"
,"missing_rate",          "f", 1, "double"
,"method",                "g", 1, "character"
,"sample_id_output_file", "h", 1, "character"
,"grm_output_file",       "i", 1, "character"
), byrow = TRUE, ncol = 4)
options <- getopt(option_specification)

cat("\nTool Directory: ", options$tool_directory)
cat("\nGenotypes File Path: ", options$genotypes_file)
cat("\nAutosome Only: ", options$autosome_only)
cat("\nRemove MonoSNPs: ", options$remove_monosnp)
cat("\nMAF: ", options$maf)
cat("\nMissing Rate: ", options$missing_rate)
cat("\nMethod: ", options$method)
cat("\nSample ID Output File Path: ", options$sample_id_output_file)
cat("\nGRM Output File Path: ", options$grm_output_file)
cat("\n\n")

sample_names <- read.table(options$genotypes_file,
                           header = FALSE,
                           sep = "\t",
                           nrows = 1,
                           row.names = NULL,
                           stringsAsFactor = FALSE)

genotype_data <- read.table(options$genotypes_file,
                            header = TRUE,
                            sep = "\t",
                            row.names = NULL,
                            stringsAsFactor = FALSE)

cat("\nSample IDs: ")
sample_names

if (options$autosome_only == "true") autosome.only <- TRUE else autosome.only <- FALSE
cat("\nautosome.only: ")
autosome.only

if (options$remove_monosnp == "true") remove.monosnp <- TRUE else remove.monosnp <- FALSE
cat("\nremove.monosnp: ")
remove.monosnp

if (options$maf == "") maf <- NaN else maf <- options$maf
cat("\nmaf: ")
maf

if (options$missing_rate == "") missing.rate <- NaN else missing.rate <- options$missing_rate
cat("\nmissing.rate: ")
missing.rate

genotype_matrix <- as.matrix(genotype_data)
gds_genotype_file <- paste(options$tool_directory, 
                           "/genotype_matrix.gds",
                           sep = "") 
cat("\n", gds_genotype_file)
snpgdsCreateGeno(gds_genotype_file, 
                 genmat = genotype_matrix)
gds_genotype_data <- snpgdsOpen(gds_genotype_file)
cat("\ncores number: ", detectCores(), "\n")
rv <- snpgdsGRM(gds_genotype_data,
                autosome.only = autosome.only,
                remove.monosnp = remove.monosnp,
                maf = maf,
                missing.rate = missing.rate,
                method = options$method,
                num.thread = detectCores(),
                with.id = TRUE)
snpgdsClose(gds_genotype_data) 

write.table(t(sample_names), 
            options$sample_id_output_file,
            sep = "\t",
            row.names = FALSE, 
            col.names = FALSE)

#colnames(rv$grm) <- NULL
#rownames(rv$grm) <- sample_names
#grm <- rbind(sample_names, rv$grm)
#write.table(grm,
write.table(rv$grm,
            options$grm_output_file,
            sep = "\t",
            #row.names = TRUE,
            row.names = FALSE,
            col.names = FALSE)
