# Umesh Rosyara, April 10, 2018
# CIMMYT
# Clustering method 3: Hierarchical k-means clustering
# this should run after finding optimal number of clustering 
################################################################
#load("/Users/urosyara/Documents/gobii/genomocic_selection_pipeline/data2.rda")

############## Example data ##################################
# dummy example data
#data1 <- data.frame ( id = paste("id", 1:20, sep=""), matrix(sample(c(1,0,-1,1,0,-1,1,0,-1,1,0,-1, NA), 2000,replace=TRUE), ncol=100))

rm(list = objects()); ls() # CLEAR 'WorkSpace'             (R  environment)

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

data1 <- read.csv(file = opt$file, header = TRUE, stringsAsFactors = FALSE)

data1c <-   data1[,-1] 

# PCA /cluster analysis works on numeric variables, so we need to code the AA=1, AB=0, BB=-1 or similar numerical encoding 

# imputation of missing values 
# this example is just imputing with mean, but the final should have better imputing algorithm 
# I think that was already in place at IRRI hackathan 
#impute with population mean
data1i <- apply(data1c[,-1],1,function(x){ix <- which(is.na(x)); x[ix] <- mean(x,na.rm=T); return(x)})

# data with no missing value 
data2 <- t(data1i)
rownames(data2) <- data1[,1]


#####################################################################
####### Hierarchical k-means clustering##### 
#The final k-means clustering solution is very sensitive to the initial random selection of cluster centers. 
#This function provides a solution using an hybrid approach by combining the hierarchical clustering and the k-means methods.
#hkmeans(x, k, hc.metric = "euclidean", hc.method = "ward.D2",
#        iter.max = 10, km.algorithm = "Hartigan-Wong")


# x	a numeric matrix, data frame or vector
# k	 the number of clusters to be generated
# hc.metric	 the distance measure to be used. Possible values are "euclidean", "maximum", "manhattan", "canberra", "binary" or "minkowski" (see ?dist).
# hc.method	the agglomeration method to be used. Possible values include "ward.D", "ward.D2", "single", "complete", "average", "mcquitty", "median"or "centroid" (see ?hclust).
# iter.max	the maximum number of iterations allowed for k-means.
# km.algorithm	the algorithm to be used for kmeans (see ?kmeans) 

require(factoextra)
result <- hkmeans(data2, k = opt$kcluster, hc.method=opt$method,hc.metric=opt$metric, iter.max= opt$iter)


# plot dendogram tree 
pdf(opt$graph)
hkmeans_tree(result, cex = 0.6)
# Visualize the hkmeans final clusters
fviz_cluster(result, ellipse.type = "norm", ellipse.level = 0.68)
dev.off()

# see the clusters
result$cluster  

# save the cluster information with data
data3 <- data.frame (data2, cluster = result$cluster)  
write.csv(data3, file = opt$clusterfile, row.names = FALSE, sep="\t",quote=FALSE,eol="\n",na=NA)

