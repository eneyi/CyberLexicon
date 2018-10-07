set.seed(1000)
library(verification)
library(ROCR)

data <- read.csv("~/Desktop/Krypton/ApplyingTheLexicon/DataAnalysis/data.csv")
data$scaled = data$scaled/100
data$binary = ifelse(data$classed=='Cyber', 1, 0)
roc.plot(x=data$binary, pred=data$scaled,xlab='False Positive Rate', ylab='True Positive Rate', main="ROC Curve for Cyber VS Non-Cyber Classifications", frame=F)
abline(v=0.21, col='red')
abline(h=0.76, col='red')



thresholds = seq(0.10,0.36,by=0.01)
aucs = c()

for(i in thresholds){
  trial = ifelse(data$scaled >= i, 1, 0)
  pred = prediction(as.numeric(data$binary), as.numeric(trial))
  perf=performance(pred, measure='auc')
  auc = perf@y.values[[1]][1]
  aucs = c(aucs, auc)
  
}

aucs = data.frame(cbind(thresholds, aucs))
aucs = aucs[order(aucs[,2]),]

