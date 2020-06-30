imputeValidataion <- function(groundDataPath, testDataPath, imputedDataPath) {
  
  #library(vcfR)
  groundTData <- read.vcfR(file = groundDataPath, verbose = FALSE, convertNA = TRUE)  #imputedData <- read.vcfR(file = "pre-test-miss0.3-imputed.vcf.gz", verbose = FALSE, convertNA = TRUE)
  imputedData <- read.vcfR(file = imputedDataPath, verbose = FALSE, convertNA = TRUE)
  inputData <- read.vcfR(file = testDataPath, verbose = FALSE, convertNA = TRUE)
  
  for (i in (2:ncol(inputData@gt))) {
    temp <- data.frame(input = inputData@gt[,i],
                       ground = groundTData@gt[,i],
                       imputed = imputedData@gt[,i],
                       correct = 0)
    miss <- temp[is.na(temp[,"input"]),]
    miss[,"ground"] <- as.character(gsub("/", "", miss[,"ground"]))
    miss[,"imputed"] <- gsub("\\|","", miss[,"imputed"])
    miss[,"imputed2"] <- as.character(gsub("10","01", miss[,"imputed"]))
    
    notImputed <- miss[is.na(miss[,"imputed2"]) & !is.na(miss[,"ground"]),]
    imputed <- miss[!is.na(miss[,"imputed2"]) & !is.na(miss[,"ground"]),]
    imputed[imputed[,"imputed2"] == imputed[,"ground"],"correct"] <- 1
    
    if (i == 2) {
      info <- data.frame(var = colnames(inputData@gt)[i],
                         correctlyImputed = sum(imputed$correct),
                         wronglyImputed = nrow(imputed) - sum(imputed$correct),
                         numImputed = nrow(imputed),
                         noImputation = nrow(notImputed))
      
    } else {
      info <- rbind(info, data.frame(var = colnames(inputData@gt)[i],
                                     correctlyImputed = sum(imputed$correct),
                                     wronglyImputed = nrow(imputed) - sum(imputed$correct),
                                     numImputed = nrow(imputed),
                                     noImputation = nrow(notImputed)))
    }
    
  }
  
  return(imputationInfo = info)
}
