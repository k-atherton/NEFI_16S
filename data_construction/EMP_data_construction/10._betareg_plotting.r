#looping models of fungal relative abundance.
#clear environment, load packages.
rm(list=ls())
source('/Users/student/Downloads/NEFI_16S-master/paths.r')
library(betareg)
setwd("~/Desktop/NEFI_16S_data/")

#load some bacterial data
map <- as.data.frame(readRDS(emp_map_clean.path)) #environmental metadata
rownames(map) <- map$`#SampleID`
taxa <- as.data.frame(readRDS("phyla_top50.rds")) #relative abundance, replace file with desired level of taxonomy
#manipulate the sample names to match the rownames of the map file
rownames(taxa) <- gsub("X","",rownames(phyla))
#match the sample names and merge data into one data frame
d <- merge(map, taxa, by="row.names")

#isolate y data (relative abundance)
y <- d[96:125] # 96:125 for phyla, 96:145 for all other levels of taxonomy

#we need to transform y data to not have any hard zeros or 1s. This is a limitation of beta regression.
#function to transform [0,1] to (0,1) a la Cribari-Neto & Zeileis 2010, statisticians who have written the most on this topic.
crib.fun <- function(x){(x * (length(x) - 1) + 0.5) / length(x)}
y <- as.data.frame(lapply(y,crib.fun))

#lets fit bacterial models as a function of ph, map, mat, map/mat cv, mdr, and aridity
preds <- c('ph','map','mat','map_CV','mat_CV','mdr','aridity')
x <- d[,preds] #just the metadata we want to look at

#setup some empty lists.
model.out <- list()
predicted.out <- list()
observed.out <- list()
#loop across the columns of y.
for(i in 1:ncol(y)){
  #setup data object
  data <- cbind(y[,i],x)
  data <- data[complete.cases(data),]
  group <- data[,1]
  #setup regression formula.
  form <- as.formula(paste0('group ~ ',paste(colnames(x), collapse="+")))
  #fit model.
  mod <- betareg(form, data = data)
  #save fitted and predicted values.
  model.out[[i]] <- mod
  predicted.out[[i]] <- fitted(mod)
  observed.out[[i]] <- data[,1]
}
names(model.out) <- colnames(y)
names(predicted.out) <- colnames(y)
names(observed.out) <- colnames(y)

#collapse predicted and observed data to a data.frame
predicted.out <- data.frame(do.call('cbind',predicted.out))
observed.out <- data.frame(do.call('cbind', observed.out))

#OR plot them all!
par(mfrow = c(5,6)) # 5,6 for phyla; 5,10 for all other levels of taxonomy
par(mar=c(1,1,1,1))
for(i in 1:ncol(observed.out)){
  mod <- lm(observed.out[,i] ~ predicted.out[,i])
  rsq <- round(summary(mod)$r.squared, 2)
  plot(observed.out[,i] ~ predicted.out[,i], cex = 0.3)
  mtext(colnames(observed.out)[i], side = 3, line = -1, adj = 0.05, cex = 0.8, col = 'purple')
  mtext(paste0('R2 = ',rsq), side = 3, line = -2.4, adj = 0.05, cex = 0.8, col = 'purple')
  #drop 1:1 line
  abline(0,1, lwd = 2)
}