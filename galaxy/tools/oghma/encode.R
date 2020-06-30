########################################################
#
# creation date : 04/01/16
# last modification : 05/01/16
# author : Dr Nicolas Beaume
# owner : IRRI
#
########################################################

library(optparse)

log <- file(paste(getwd(), "log_encode.txt", sep="/"), open = "wt")
sink(file = log, type="message")

############################ helper functions #######################

# encode one position in one individual
encodeGenotype.position <- function(x, major, code=c(0,1,2), sep=""){
  res <- x
  if(!is.na(x)) {
    if(isHeterozygous(x, sep = sep)) {
      # heterozygous
      res <- code[2]
    } else {
      # determine whether it is the minor or major allele
      x <- unlist(strsplit(x, sep))
      # need to check only one element as we already know it is a homozygous
      if(length(x) > 1) {
        x <- x[1]
      }
      if(x==major) {
        res <- code[3]
      } else {
        res <- code[1]
      }
    }
  } else {
    res <- NA
  }
  return(res)
}

# rewrite a marker to determine the major allele
encodeGenotype.rewrite <- function(x, sep=""){
  res <- x
  if(!is.na(x)) {
    if(length(unlist(strsplit(x,sep)))==1) {
      # in case of homozygous, must be counted 2 times
      res <- c(x,x)
    } else {
      res <- unlist(strsplit(x, split=sep))
    }
  } else {
    res <- NA
  }
  return(res)
}

# encode one individual
encodeGenotype.vec <- function(indiv, sep="", code=c(0,1,2)){
  newIndiv <- unlist(lapply(as.character(indiv), encodeGenotype.rewrite, sep))
  stat <- table(as.character(newIndiv))
  major <- names(stat)[which.max(stat)]
  indiv <- unlist(lapply(indiv, encodeGenotype.position, major, code, sep))
  return(indiv)
}


isHeterozygous <- function(genotype, sep=""){
  bool <- F
  if(is.na(genotype)){
    bool <- NA
  } else {
    x <- unlist(strsplit(genotype, sep))
    if(length(x) > 1 & !(x[1] %in% x[2])) {
      bool <- T
    }
    
  }
  return(bool)
}

################################## main function ###########################
# encode all individuals
# encode genotype into a {-1,0,1} scheme, where -1 = minor homozygous, 0 = heterozygous, 1 = major homozygous
encodeGenotype <- function(raw, sep="", code=c(0,1,2), outPath){
  encoded <- apply(raw, 2, encodeGenotype.vec, sep, code)
  write.table(encoded, file=outPath, row.names = FALSE, sep="\t")
}

############################ main #############################
# running from terminal (supposing the OghmaGalaxy/bin directory is in your path) :
# encode.sh -i path_to_raw_data -s separator -c code -o path_to_result_directory 
## -i : path to the file that contains the genotypes to encode, must be a .rda file (as outputed by loadGenotype.R).
# please note that the table must be called "genotype" when your datafile is saved into .rda (automatic if loadGenotype.R was used)

## -s : in case of heterozygous both allele are encoded in the same "cell" of the table and separated by a character
# (most often "" or "/"). This argument specify which character

## -c : the encoding of minor allele/heterozygous/major allele. by default {-1,0,1}

## -o : path to the file of encoded genotype. the .rda extension is automatically added

#cmd <- commandArgs(T)
#source(cmd[1])
#genotype <- read.table(genotype, sep="\t", stringsAsFactors = FALSE, header=TRUE)

# deal with optional argument
#code <- strsplit(code, ",")
#code <- unlist(lapply(code, as.numeric), use.names = F)
#encodeGenotype(raw=genotype, sep=sep, code = code, outPath = out)
#cat(paste(out,".csv", "\n", sep=""))

option_list <- list(
  make_option(c("-v", "--verbose"), action="store_true", default=TRUE,
              help="Print extra output [default]"),
  make_option(c("-q", "--quietly"), action="store_false",
              dest="verbose", help="Print little output"),
  make_option(c("-i", "--input_file"), type="character", default="input.csv",
              help="path to the file that contains the genotypes to encode",
              metavar="inputfile"),
  make_option(c("-s", "--het_separator"), type="character", default="/",
              help="in case of heterozygous both allele are encoded in the same cell of the table and separated by a character. This argument specify which character",
              metavar="separator"),
  make_option(c("-c", "--coding"), type="character", default="{-1,0,1}",
              help="the encoding of minor allele/heterozygous/major allele",
              metavar="coding"),
  make_option(c("-o", "--output"), type="character", default="test_data/",
              help="encoded genotype.",
              metavar="output")
)
#parse_args(OptionParser(option_list = option_list))
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

genotype <- read.table(opt$i, sep="\t", stringsAsFactors = FALSE, header=TRUE)
code <- strsplit(opt$c, ",")
code <- unlist(lapply(code, as.numeric), use.names = F)
encodeGenotype(raw=genotype, sep=opt$s, code = code, outPath = opt$o)
#cat(paste(opt$o,".csv", "\n", sep=""))