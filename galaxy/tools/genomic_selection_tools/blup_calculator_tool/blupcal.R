# Calculation of BLUE/BLUP
# Umesh Rosyara, CIMMYT
blupcal<- function(data,  
                   Replication = "Rep", 
                   Genotype    = "Entry", 
                   y           = "y", 
                   design      = "rcbd",
                   Block       = NULL,
                   summarizeby = NULL, 
                   groupvar1   = NULL, 
                   groupvar2   = NULL) {

  suppressMessages(library(arm))
  # so that it would not throw messages at the stderr channel of Galaxy
  library(lme4, quietly = TRUE)

  # Basic summary of the variables eused  
  print(paste("Replication variable = ", Replication))
  print(paste("block variable = ", Block))  
  print(paste("Genotype variable = ", Genotype))
  print(paste("summarizeby (included in the model) = ", summarizeby))
  print(paste("groupvariable 1 (included in the model) = ", groupvar1))
  print(paste("groupvariable 2 (included in the model) = ", groupvar2))
  print(paste("design = ", design))
  print(paste("y = ", y))

  # Summary of data
  print("*************************************")
  print("*************************************")
  print(summary(data))
  print("*************************************")
  print("*************************************")

  data_list <- list()
  if (length(summarizeby) != 0) {
    data$summarizeby <- as.factor(data[,summarizeby])
    data_list = split(data, f = data$summarizeby)
  } else {
    data$summarizeby <- "none"
    data_list[[1]] <- data
  }

  all_results <- list()

  for (i in 1: length(data_list)) {
    data1 <- data_list[[i]]

    data1$Rep <- as.factor(data1[, Replication])
    cat("\ndata1$Rep:\n")
    print(data1$Rep)

    data1$Entry <- as.factor(data1[, Genotype])
    cat("\ndata1$Entry:\n")
    print(data1$Entry)

    if (design == "lattice") {
      data1$Subblock <- as.factor(data1[, Block])
    }

    data1$y <- as.numeric(data1[, y])
    cat("\ndata1$y:\n")
    print(data1$y)

    if (length(groupvar1) != 0) {
      data1$groupvar1 <- as.factor(data1[, groupvar1])
      cat("\ndata1$groupvar1:\n") 
      print(data1$groupvar1) 
    }

    if (length(groupvar2) != 0) {
      data1$groupvar2 <- as.factor(data1[, groupvar2])
      cat("\ndata1$groupvar2:\n") 
      print(data1$groupvar2) 
    }

    if (design == "rcbd") {
      if (length(groupvar1) != 0) {
        if (length(groupvar2) != 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|groupvar1) + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar1) + 
                          (1|Entry:groupvar2) + 
                          (1|Entry:groupvar1:groupvar2) + 
                          (1|Rep), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|groupvar1) + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar1) + 
                          (1|Entry:groupvar2) + 
                          (1|Entry:groupvar1:groupvar2) + 
                          (1|Rep), 
                      data1)
        }
        if (length(groupvar2) == 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|groupvar1) + 
                          (1|Entry:groupvar1) + 
                          (1|Rep), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|groupvar1) + 
                          (1|Entry:groupvar1) + 
                          (1|Rep), 
                      data1) 
        }
      }
      if (length(groupvar1) == 0) {
        if (length(groupvar2) != 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar2) + 
                          (1|Rep), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar2) + 
                          (1|Rep), 
                      data1)
        }
        if (length(groupvar2) == 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|Rep), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|Rep), 
                      data1)
        }
      }
    }

    if (design == "lattice") {
      if (length(groupvar1) != 0) {
        if (length(groupvar2) != 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|groupvar1) + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar1) + 
                          (1|Entry:groupvar2) + 
                          (1|Entry:groupvar1:groupvar2) + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|groupvar1) + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar1) + 
                          (1|Entry:groupvar2) + 
                          (1|Entry:groupvar1:groupvar2) + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1)
        }
        if (length(groupvar2) == 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|groupvar1) + 
                          (1|Entry:groupvar1) + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|groupvar1) + 
                          (1|Entry:groupvar1) + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1) 
        }
      }
      if (length(groupvar1) == 0) {
        if (length(groupvar2) != 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar2) + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|groupvar2) + 
                          (1|Entry:groupvar2) + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1)
        }
        if (length(groupvar2) == 0) {
          fm1 <- lmer(y ~ 1 + 
                          (1|Entry) + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1)
          fm2 <- lmer(y ~ (-1) + 
                          Entry + 
                          (1|Rep) + 
                          (1|Rep:Subblock), 
                      data1)
        }
      }
    }
 
    cat("\nfm1:\n")
    print(fm1)
    cat("\nfm2:\n")
    print(fm2)
 
    mean1 <- mean(data1$y, na.rm = TRUE) 
    tp <- ranef(fm1)$Entry
    if (all(tp == 0)) {
      stop("error in model: all BLUP effects are zero")
    }

    ######## 
    # BLUP 
    ######## 
    blup <- tp + mean1
    names(blup) <- "blup"

    varComponents <- as.data.frame(VarCorr(fm1))

    # extract the genetic variance component
    Vg <- varComponents[match('Entry', varComponents[,1]), 'vcov']

    # This function extracts standard errors of model random effect from modeled object in lmer
    SErr <- se.ranef(fm1)$Entry[,1]

    # Prediction Error Variance (PEV)
    PEV <- (SErr) ^ 2

    # PEV reliability
    pevReliability <- 1 - (PEV / Vg)
    names(pevReliability) <- "PEV reliability"

    blupdf = data.frame(genotype = rownames(ranef(fm1)$Entry), 
                        blup = blup,
                        BLUP_PEV = PEV,  
                        BLUP_pevReliability = pevReliability)

    ######## 
    # BLUE 
    ######## 
    blue <- fixef(fm2)

    bluedf <- data.frame(genotype = substr(names(blue), 6, nchar(names(blue))), 
                         blue = blue)

    ######### 
    # MEANS 
    ######### 
    means <- with(data1, tapply(y, Entry, mean, na.rm = TRUE))

    meandf <- data.frame(genotype = names(means), 
                         means = means)
    
    resultdf1 <- merge(meandf, bluedf, by = "genotype")
    resultdf <- merge(resultdf1, blupdf, by = "genotype")

    if (length(summarizeby) != 0) {
      results <- data.frame(row.names      = NULL, 
                            genotype       = resultdf$genotype, 
                            blue           = resultdf$blue, 
                            blup           = resultdf$blup,
                            BLUP_PEV       = resultdf$BLUP_PEV,  
                            pevReliability = resultdf$BLUP_pevReliability, 
                            means          = resultdf$means, 
                            group          = levels(data$summarizeby)[i])
      names(results) <- c(Genotype, 
                          paste(y, "_blue", sep = ""), 
                          paste(y, "_blup", sep = ""), 
                          paste(y, "_PEV", sep = ""), 
                          paste(y, "_pevReliability", sep = ""), 
                          paste(y, "_means", sep = ""), 
                          summarizeby)
    } else {
      results <- data.frame(row.names      = NULL, 
                            genotype       = resultdf$genotype, 
                            blue           = resultdf$blue, 
                            blup           = resultdf$blup, 
                            BLUP_PEV       = resultdf$BLUP_PEV,  
                            pevReliability = resultdf$BLUP_pevReliability, 
                            means          = resultdf$means)
      names(results) <- c(Genotype, 
                          paste(y, "_blue", sep = ""), 
                          paste(y, "_blup", sep = ""), 
                          paste(y, "_PEV", sep = ""), 
                          paste(y, "_pevReliability", sep = ""), 
                          paste(y, "_means", sep = ""))
    }

    all_results[[i]] <- results 
  }
  outdf <- do.call("rbind", all_results)
  class(outdf) <- c("blupcal", class(outdf))
  return(outdf)
}

# plot function of blupcal module 
plot2.blupcal <- function(outdf) {
  hist_with_box <- function(data, main = main, hist.col, box.col) {
    histpar <- hist(data, plot = FALSE)
    hist(data, col = hist.col, main = main, ylim = c(0, max(histpar$density) + max(histpar$density) * 0.3), prob = TRUE)
    m = mean(data, na.rm = TRUE)
    std = sd(data, na.rm = TRUE)
    curve(dnorm(x, mean = m, sd = std), col = "yellow", lwd = 2, add = TRUE, yaxt = "n")
    boxout <- boxplot(data, plot = FALSE)
    points(boxout$out, y = rep(max(histpar$density) * 0.3, length(boxout$out)), col = "red", pch = 1)
    texts <- paste("mean = ", round(mean(data, na.rm = TRUE), 2), " sd = ", round(sd(data, na.rm = TRUE), 2), " n = ", length(data))
    text(min(histpar$breaks), max(histpar$density) + max(histpar$density) * 0.2, labels = texts, pos = 4)
  }
  par(mfrow = c(3,1), mar = c(3.1, 3.1, 1.1, 2.1))
  hist_with_box(outdf[,2], main = names(outdf)[2], hist.col = "green4", box.col = "green1")
  hist_with_box(outdf[,3], main = names(outdf)[3], hist.col = "blue4", box.col = "blue1")
  hist_with_box(outdf[,4], main = names(outdf)[4], hist.col = "gray20", box.col = "gray60")
}
