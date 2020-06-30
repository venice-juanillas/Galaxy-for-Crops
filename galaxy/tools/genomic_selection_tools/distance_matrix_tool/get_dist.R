#rm(list = objects()); ls() # CLEAR 'WorkSpace'             (R  environment)

library(optparse)
#library(heatmaply)
require(factoextra)
library(plotly)

option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="dataset file name", metavar="input_file"),
  make_option(c("-m", "--method"), type="character", default="euclidean", 
              help="the distance measure to be used", metavar="method "),
  make_option(c("-d", "--distance"), type="character", default="pairwise_dist.txt", 
              help="pairwise distance [default= %default]", metavar="pairwise_dist"),
  make_option(c("-g", "--graph"), type="character", default="graph.pdf", 
              help="Graph File [default= %default]", metavar="graph_file")
); 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$file)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).\n", call.=FALSE)
}

dataMatrix <- read.csv(file= opt$file, header = TRUE, stringsAsFactors = FALSE)
s1 <- dataMatrix[,-1]
dataMT <- as.matrix(t(s1))

distance <- get_dist(dataMT,stand=TRUE, method=opt$m)
write.csv(as.matrix(distance), file=opt$d, na="NA")

pdf(opt$g)
fviz_dist(distance, gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"))
dev.off()
