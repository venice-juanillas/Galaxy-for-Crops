# Umesh Rosyara, April 10, 2018
# CIMMYT
# Clustering method 3: Hierarchical k-means clustering
# this should run after finding optimal number of clustering 
################################################################
require(factoextra)
library(optparse)

option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL,
              help="dataset file name", metavar="input_file"),
  make_option(c("-d", "--dmetric"), type="character", default="euclidean",
              help="the distance measure to be used", metavar="distance_metric "),
  make_option(c("-a", "--algorithm"), type="character", default="Hartigan-Wong",
              help="the algorithm to be used for kmeans", metavar="algorithm "),
  make_option(c("-m", "--method"), type="character", default="ward.D",
              help="the agglomeration method to be used", metavar="method "),
  make_option(c("-k", "--kcluster"), type="integer", default=2,
              help=" the number of clusters to be generated", metavar="num of clusters to generate"),
  make_option(c("-i", "--iter"), type="integer", default=10,
              help="the maximum number of iterations allowed for k-means", metavar="iterations "),
  make_option(c("-c", "--clusterfile"), type="character", default="cluster_file.txt",
              help="Cluster membership file[default= %default]", metavar="membership_file"),
  make_option(c("-g", "--graph"), type="character", default="graph.html",
              help="Graph File [default= %default]", metavar="graph_file")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$file)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).\n", call.=FALSE)
}


## read data and count number of metadata lines to skip
data <-readLines(con<-opt$f)
lines2skip <- grep("^[^#]",data)[1]-1

## read data and create the dataframe hapmap
hapmap <- read.delim(opt$f,sep="\t", header = TRUE, na.strings = "NA", skip = lines2skip)

## subset the hapmap by removing extra marker metadata
## will be left with marker X sample snp matrix
geno.hapmap <- hapmap[-c(1:11)]

## transpose matrix
t.geno.hapmap <- t(geno.hapmap)

## calculate optimal number of clusters
#optClst1<- fviz_nbclust(geno.hapmap, FUNcluster = kmeans, method = "silhouette") + labs(subtitle = "Silhouette method")
#optClust2<- fviz_nbclust(geno.hapmap, FUNcluster = kmeans, method = "wss") + labs(subtitle = "Elbow method")
#optClust3<- fviz_nbclust(geno.hapmap, FUNcluster = kmeans, method = "gap_stat",nstart= 25, nboot = 50) + labs(subtitle = "Gap Statistics Method")

print(opt$k)
print(opt$m)
print(opt$a)
print(opt$i)

## do clustering
result = hkmeans(t.geno.hapmap, k = opt$k, hc.method= opt$m, hc.metric= opt$a, iter.max= opt$i)

## create dendogram
pdf(opt$g)
hkmeans_tree(result, cex = 0.6)
#fviz_cluster(result, ellipse.type = "norm", ellipse.level = 0.68)
fviz_dend(result, rect = TRUE, cex = 0.5,palette = "jco", rect_border = "jco", rect_fill = TRUE)
dev.off()

## create the cluster or membership file and output to a tab-delimited file
clusterdata <- data.frame(row.names(t.geno.hapmap), cluster = result$cluster)
write.table(clusterdata,file=opt$g, row.names = FALSE,col.names = FALSE, sep="\t", quote = FALSE)
