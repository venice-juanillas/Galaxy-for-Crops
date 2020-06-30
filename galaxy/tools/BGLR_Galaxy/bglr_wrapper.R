#!/usr/bin/Rscript

options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)});
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8");
library("getopt");
library("BGLR");

options(stringAsfactors = FALSE, useFancyQuotes = FALSE);
options(warn = -1);
args <- commandArgs(trailingOnly = TRUE);
option_specification = matrix(c(
'csv_file', 'l', 1, 'character',
'name_vector_column','n',1,'integer',
'data_vector_column', 'y', 1, 'integer', 
'response_type', 'r', 1, 'character',
'lower_bound_vector_column', 'a', 1, 'integer',
'upper_bound_vector_column', 'b', 1, 'integer',
'eta', 'e', 1, 'character',
'weights_vector_column', 'w', 1, 'integer',
'number_of_iterations', 'i', 1, 'integer',
'burnin', 'u', 1, 'integer',
'thinning', 't', 1, 'integer',
'saveat', 's', 1, 'character',  
's0', 'c', 2, 'character',  
'df0', 'd', 1, 'double',  
'r2', 'p', 1, 'double',  
'verbose', 'v', 1, 'logical',  
'rmexistingfiles', 'f', 1, 'logical',
'kfold','k',1,'integer',
'nrandom','m',1,'integer',
'p_out','j',1,'integer',
'groups_vector_column', 'g', 1, 'integer',  
'png_file_path', 'o', 1, 'character', 
'pdf_file_path', 'x', 1, 'character',
'csv_file_path', 'q', 1, 'character'
), byrow = TRUE, ncol = 4);
options = getopt(option_specification);

#cat("\nCSV File: ", options$csv_file);
#cat("\nData-vector Column: ", options$data_vector_column);
#cat("\nResponse Type: ", options$response_type);
#cat("\nLower Bound (a) Vector Column: ", options$lower_bound_vector_column);
#cat("\nUpper Bound (b) Vector Column: ", options$upper_bound_vector_column);
#cat("\nETA: ", options$eta);
#cat("\nWeights Vector Column: ", options$weights_vector_column);
#cat("\nNumber of Iterations: ", options$number_of_iterations);
#cat("\nBurn-In: ", options$burnin);
#cat("\nThinning: ", options$thinning);
#cat("\nsaveAt: ", options$saveat);
#cat("\nS0: ", options$s0);
#cat("\ndf0: ", options$df0);
#cat("\nR2: ", options$r2);
#cat("\nverbose: ", options$verbose);
#cat("\nrmExistingFiles: ", options$rmexistingfiles);
#cat("\nGroups Vector Column: ", options$groups_vector_column);
#cat("\nPNG file path: ", options$png_file_path);
#cat("\nPDF file path: ", options$pdf_file_path);

#stop("Test");

## getting al the arguments

csv_data <- read.csv(file=options$csv_file, header=TRUE, sep=",");
sampleNames<-c(as.character(csv_data[[options$name_vector_column]]));
y <- c(as.numeric(csv_data[[options$data_vector_column]]));
cat("\n\ny: ", y); 
columnNames=colnames(csv_data)
response_type <- options$response_type;
cat("\nresponse_type: ", response_type);

if (is.na(options$lower_bound_vector_column)) a <- NULL else a <- c(as.numeric(csv_data[[options$lower_bound_vector_column]]));
cat("\na: ");
a;

if ((!(is.null(a))) & (length(a) != length(y))) cat ("Length incompatibility between the y and a vectors!");  

if (is.na(options$upper_bound_vector_column)) b <- NULL else b <- c(as.numeric(csv_data[[options$upper_bound_vector_column]]));
cat("b: ");
b;
if ((!(is.null(b))) & (length(b) != length(y))) cat ("Length incompatibility between the y and b vectors!");  

#if (options$eta == "NULL") ETA <- NULL else load(options$eta);
#spliting eta string into a list of files and model specifications
etaList=strsplit(options$eta,",")
#etaList=strsplit(eta,",")
#getting number of incidence matrice/model combinations
etaSize=length(etaList[[1]])/2
#if the array is empty ETA is set to the default NULL
if(etaSize==0){
	ETA="NULL"
} else {
	#looping through the array to create the ETA list
	ETA<-list()
	i=1
	count=1
	while(i<=length(etaList[[1]])){
		mat=read.csv(etaList[[1]][i],header=TRUE,sep=',')
		model=etaList[[1]][i+1]
		ETA[[count]]=list(X=assign(paste("X",count,sep=''),t(as.matrix(mat))),model=as.character(model))
		count=count+1
		i=i+2		
	}
}
cat("ETA: ");
ETA;

if (is.na(options$weights_vector_column)) weights <- NULL else weights <- c(as.numeric(csv_data[[options$weights_vector_column]]));
cat("weights: ");
weights;
if ((!(is.null(weights))) & (length(weights) != length(y))) cat ("Length incompatibility between the y and weights vectors!");  

nIter <- options$number_of_iterations;
cat("nIter: ", nIter);

burnIn <- options$burnin;
cat("\nburnIn: ", burnIn);

thin <- options$thinning;
cat("\nthin: ", thin);

saveAt <- options$saveat;
cat("\nsaveAt: ", saveAt);

if (options$s0 == "NULL") S0 <- NULL else S0 <- eval(parse(text=options$s0));
cat("\nS0: ");
S0;
#if(!(is.numeric(S0))) cat("S0, ", S0, ", is not numeric!\n"); 

df0 <- options$df0;
cat("df0: ", df0);

R2 <- options$r2;
cat("\nR2: ", R2);

verbose <- options$verbose;
cat("\nverbose: ", verbose);

rmExistingFiles <- options$rmexistingfiles;
cat("\nrmExistingFiles: ", rmExistingFiles);

if (is.na(options$groups_vector_column)) groups <- NULL else groups <- c(as.numeric(csv_data[[options$groups_vector_column]]));
cat("\ngroups: ");
groups;
if ((!(is.null(groups))) & (length(groups) != length(y))) cat ("Length incompatibility between the y and groups vectors!");  

pngFilePath <- options$png_file_path;
#cat("\n\nPNG File Path: ", pngFilePath);
pdfFilePath <- options$pdf_file_path;
#cat("\nPDF File Path: ", pdfFilePath, "\n");
csvFilePath <- options$csv_file_path;

Nrand = options$nrandom
folds = options$kfold
pout = options$p_out
if(!(is.na(pout))){
	folds=ceiling(length(y)/pout)
}
print("CV Parms")
print(pout)
print(folds)
print(Nrand)

if(!(is.na(Nrand)) && !(is.na(folds))){
	predicted=rep(0,Nrand*length(y))
	estimates=rep(0,length(y))
	trueValues=rep(y,Nrand)
	correlations=rep(0,Nrand*folds)
	currentCorrelations=rep(0,folds)
	indexes=c(1:length(y))
	header<-paste('Observed Trait','Prediction','Correlation')
	cvNum=1
	#calculate fold sizes
	fs = floor(length(y)/folds)
	foldsize=rep(0,folds)
	for(i in c(1:folds)){
		if(i==folds){
			foldsize[i]=length(y)-(i-1)*foldsize
		} else {
			foldsize[i]=fs
		}
	}
	write(header,file=csvFilePath,ncol=3,sep=",",append=TRUE)
	for(i in c(1:Nrand)){ ## number of times to randomize samples
		randIndex=sample(indexes)
   	    count=0
		## create the folds
   	    for(j in c(1:folds)){ 
   	     	yt=y
			## for one of the folds, replace the observed value with NA
   	     	yv=rep(NA,length(y))
    		    	for(k in c(1:foldsize[j])){
       	        	yt[randIndex[(count+k)]]=NA
                	yv[randIndex[(count+k)]]=y[randIndex[count+k]]           	
             }
    		## fitting
            fit=BGLR(y=yt, response_type=response_type, a=a, b=b, ETA=ETA, weights=weights, nIter=nIter, burnIn=burnIn, thin=thin, saveAt=saveAt, S0=S0, df0=df0, R2=R2, verbose=verbose, rmExistingFiles=rmExistingFiles, groups=groups);
			
			for(k in c(1:foldsize[j])){
       	        	estimates[randIndex[count+k]]=fit$yHat[randIndex[count+k]]
                         	
             }		
		    ##populate predictions
            #correlations[cvNum]=
            #currentCorrelations[j]=correlations[cvNum]
            cvNum=cvNum+1
            count=count+foldsize[j]
	
        }
		##output the list of correlations
		write('Summary:',file=csvFilePath, sep="\n",append=TRUE)
		write('Correlation:',file=csvFilePath,append=TRUE)
		correlation=cor(estimates,y)
		write(correlation,file=csvFilePath, sep="\n",append=TRUE)
		start=(i-1)*length(y)+1
		stop=i*length(y)
		predicted[start:stop]=estimates
	}
	if (!(is.null(pngFilePath))) {
			png(pngFilePath);
			plot(predicted,trueValues);
			dev.off(); 
	}
	if (!(is.null(pdfFilePath))) {
		pdf(pdfFilePath);
		plot(predicted,trueValues);
		dev.off(); 
	}


} else {
	## do BGLR
	fit=BGLR(y=y, response_type=response_type, a=a, b=b, ETA=ETA, weights=weights, nIter=nIter, burnIn=burnIn, thin=thin, saveAt=saveAt, S0=S0, df0=df0, R2=R2, verbose=verbose, rmExistingFiles=rmExistingFiles, groups=groups);
	#creating output file for phenotypes and predictions
	header=c("Name",paste("Observed",columnNames[options$data_vector_column],sep="_"),paste("Predicted",columnNames[options$data_vector_column],sep="_"))
	outData=cbind(sampleNames,y,fit$yHat)
	write(t(header),file=csvFilePath,ncol=3, sep=",")
	write(t(outData),file=csvFilePath,ncol=3, sep=",",append=TRUE)
	if (!(is.null(pngFilePath))) {
		png(pngFilePath);
		plot(fit);
		dev.off(); 
	}
	if (!(is.null(pdfFilePath))) {
		pdf(pdfFilePath);
		plot(fit);
		dev.off(); 
	}
}



