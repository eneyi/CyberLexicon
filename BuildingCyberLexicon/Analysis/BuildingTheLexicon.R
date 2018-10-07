#building the krypton lexicon
setwd("/Users/crypteye/OneDrive/School/Papers/Krypton/")
set.seed(1000)

library(tm)
library(Matrix)
library(stringi)
library(wordcloud)
library(chinese.misc)

#calculates information entropy of a term using shannon's entropy
termEntropy = function(term){
  #get unique characters in term
  unchars = unique(strsplit(term, "")[[1]])
  probs = length(unchars)/length(term)
  -sum(probs * log(probs))
}

#returns
splitText = function(x){
  splitted = strsplit(x, " ")[[1]]
  splitted[splitted!=""]
}


#normalize a numeric vector
normed = function(x){
  mm = mean(x)
  s = sd(x)
  (x-mm)/s
}

#read in data
cwnFile = read.delim("BuildingTheLexicon/DataPreprocessing/outputfiles/cwn.txt", sep='\t', encoding="UTF-8")
redditFile = read.delim("BuildingTheLexicon/DataPreprocessing/outputfiles/reddit.txt", sep='\t', encoding="UTF-8")
stackFile = read.delim("BuildingTheLexicon/DataPreprocessing/outputfiles/stack.txt", sep='\t', encoding="UTF-8")
twitterFile = read.delim("BuildingTheLexicon/DataPreprocessing/outputfiles/twitter.txt", sep='\t', encoding="UTF-8")
hackernewsFile = read.delim("BuildingTheLexicon/DataPreprocessing/outputfiles/hackernews.txt", sep='\t', encoding="UTF-8")


#test
cwnTest = unlist(lapply(as.character(cwnFile[,1]), function(dn)ifelse(length(splitText(dn))>2, T,F)))
redditTest = unlist(lapply(as.character(redditFile[,1]), function(dn)ifelse(length(splitText(dn))>2, T,F)))
stackTest = unlist(lapply(as.character(stackFile[,1]), function(dn)ifelse(length(splitText(dn))>2, T,F)))
twitterTest = unlist(lapply(as.character(twitterFile[,1]), function(dn)ifelse(length(splitText(dn))>2, T,F)))
hackernewsTest = unlist(lapply(as.character(hackernewsFile[,1]), function(dn)ifelse(length(splitText(dn))>2, T,F)))


#get text
cwnText = unique(as.character(cwnFile[,1]))[cwnTest]
redditText = unique(as.character(redditFile[,1]))[redditTest]
stackText = unique(as.character(stackFile[,1]))[stackTest]
twitterText = unique(as.character(twitterFile[,1]))[twitterTest]
hackernewsText = unique(as.character(hackernewsFile[,1]))[hackernewsTest]


corpus1 = unlist(c(cwnText,redditText,stackText,twitterText, hackernewsText))

#get length documents
docsLen = unlist(lapply(corpus1, function(dn)length(splitText(dn))))

#make corpus
corpus1 = VCorpus(VectorSource(corpus1))


##create term document matrix
minFreq = 10
cdtm = DocumentTermMatrix(corpus1, control=list(bounds=list(global=c(minFreq, Inf), weighting=weightBin)))



#entropies
entropies = unlist(lapply(colnames(cdtm),termEntropy))
cdtm = cdtm[,entropies!=0]
cdtm = removeSparseTerms(cdtm, 0.9995)

#write out terms for manual curation
write.table(colnames(cdtm), "BuildingTheLexicon/Analysis/terms2.txt", row.names=F,quote=F)

#read in terms after curation
terms <- read.csv("BuildingTheLexicon/Analysis/terms.txt",col.names = FALSE)
cdtm = cdtm[,as.character(terms[,1])]
term_cor = cor(as.matrix(cdtm))

#create sparse matrix
sparse1 = sparseMatrix(i=cdtm$i, j = cdtm$j, x=cdtm$v, dims = c(cdtm$nrow, cdtm$ncol), dimnames=dimnames(cdtm))

#create co-occurance matrix
#cooccur = t(sparse1) %*% sparse1
x = create_ttm(cdtm, type="dtm")
cooccur = as.matrix(x$value)
rownames(cooccur) = x$word
colnames(cooccur) = x$word

tt=data.frame(as.matrix(cdtm))

#normalize by document lengths
ntf=data.frame(sapply(1:ncol(tt), function(dn)tt[,dn]/docsLen))


#term freq
fq = colSums(tt)
nfq = colSums(ntf)

#term degree
degree= colSums(cooccur)-diag(cooccur)
#term degree-frequency ratio
ratio = degree/fq
ratio = normed(ratio)

fdr = data.frame(degree=degree,frequency=fq,ratio=ratio, terms=colnames(tt))
fdr = fdr[order(fdr$ratio, decreasing=T),]
fdr$terms = rownames(fdr)
write.csv(fdr, "BuildingTheLexicon/Analysis/frequency_degree_ratio.csv")

wordcloud(words=rownames(fdr)[0:383], freq=fdr$ratio[1:383], min.freq=1, max.words=nrow(tfidf_scores)*(1/3), rot.per=0.35, colors=brewer.pal(8, "Dark2"), use.r.layout=F,random.order=FALSE, scale=c(2,0.1))
plot(1:nrow(fdr),fdr$ratio, type='l',frame=F, main="Frequency-Degree Ratio Scores", ylab="FDR Scores", xlab="", lwd=2, col='dodgerblue')


###tf-idf score




tfidf = data.frame(sapply(tt, function(dn)ifelse(dn>0,1,0)))
tdifsums = colSums(tfidf)
tfidf_scores = normed(log(nrow(tt)/tdifsums)*fq)
tfidf_scores = data.frame(tdif=tfidf_scores, terms=colnames(tfidf))
tfidf_scores=tfidf_scores[order(tfidf_scores$tdif, decreasing=T),]
write.csv(tfidf_scores, "BuildingTheLexicon/Analysis/tfidf_scores.csv")

wordcloud(words=tfidf_scores$terms[0:383], freq=tfidf_scores$tdif[1:383], min.freq=1, max.words=nrow(tfidf_scores)*(1/3), rot.per=0.35, colors=brewer.pal(8, "Dark2"), use.r.layout=F,random.order=FALSE, scale=c(3,0.3))
plot(1:nrow(tfidf_scores),tfidf_scores$tdif, type='l',frame=F, main="Term-Frequency Inverse Document Frequency Scores", ylab="TF-IDF Scores", xlab="", lwd=2, col='dodgerblue')



###creating PMI Matrix
contextMat = data.frame(as.matrix(cooccur))
#lap lacing
contextMat = data.frame(sapply(contextMat, function(dn)dn+2))

diag(contextMat) = 0

#create zero-matrix with n-cols and n-rows where n = number of candidate terms
pmiMat = matrix(0,ncol=ncol(contextMat), nrow=nrow(contextMat))
total = sum(contextMat)

for (i in 1:ncol(contextMat)){
  for(j in 1:nrow(contextMat)){

    pij = contextMat[i,j]/total
    pi = sum(contextMat[,i])/total
    pj = sum(contextMat[j,])/total
    pmiMat[i,j] = log2(pij/(pi*pj))
  }
}


pmiTrial = pmiMat
pmiTrial = data.frame(sapply(1:ncol(pmiTrial), function(dn)ifelse(pmiTrial[,dn]==-Inf, 0, pmiTrial[,dn])))
colnames(pmiTrial) = colnames(contextMat)
rownames(pmiTrial) = colnames(contextMat)
pmiTrial =data.frame(pmiTrial)


apmis = colSums(pmiTrial)
apmis = data.frame(terms=colnames(pmiTrial), apmis=apmis)
apmis=apmis[order(apmis$apmis, decreasing=T),]
absapmis = apmis
absapmis$apmis = normed(abs(absapmis$apmis))
absapmis=absapmis[order(absapmis$apmis, decreasing=T),]
write.csv(absapmis, "BuildingTheLexicon/Analysis/absapmis.csv")

write.csv(apmis, "BuildingTheLexicon/Analysis/apmis.csv")

wordcloud(words=apmis$terms[0:383], freq=abs(apmis$apmis)[1:383], min.freq=1, max.words=nrow(tfidf_scores)*(1/3), rot.per=0.35, colors=brewer.pal(8, "Dark2"), use.r.layout=F,random.order=FALSE, scale=c(3,0.3))
plot(1:nrow(apmis),apmis$apmis, type='l',frame=F, main="Aggregated Point-Wise Information Scores", ylab="APMIS Scores", xlab="", lwd=3, col='dodgerblue')



ranked = merge(merge(tfidf_scores, fdr, by='terms'), absapmis, by='terms')
ranked$agg = (ranked$tdif+ranked$ratio+ranked$apmis)/3
ranked = ranked[order(ranked$agg, decreasing = T),]
rownames(ranked) = ranked$terms
write.csv(ranked, "BuildingTheLexicon/Analysis/ranked.csv")


top_ratio = as.character(fdr$terms[1:420])
top_tfidf = as.character(tfidf_scores$terms[1:420])
top_apmis = as.character(apmis$terms[1:420])
collated = c(top_ratio,top_tfidf,top_apmis)
collated=unique(collated)
t2 = ranked[collated,]
t2=t2[complete.cases(t2),]
write.csv(ranked, "BuildingTheLexicon/Analysis/t2.csv")






#746 terms
png("DistributionOfTermScores", width=1500, height=700)
par(mfrow=c(1,3))
plot(1:nrow(apmis),apmis$apmis, type='l',frame=F, main="Distribution Of APMIS Scores", ylab="APMIS Scores", xlab="Term Rank", lwd=3, col='dodgerblue')
plot(1:nrow(tfidf_scores),tfidf_scores$tdif, type='l',frame=F, main="Distribution Of TF-IDF Scores", ylab="TF-IDF Scores", xlab="Term Rank", lwd=2, col='dodgerblue')
plot(1:nrow(fdr),fdr$ratio, type='l',frame=F, main="Distribution Of FDR Scores", ylab="FDR Scores", xlab="Term Rank", lwd=2, col='dodgerblue')
par(mfrow=c(1,1))
dev.off()



plot(1:nrow(apmis),apmis$apmis, type='l',frame=F, main="Distribution Of Term Scores By Scoring Mechanisms", ylab="Term Scores", xlab="Term Index", lwd=3, col='dodgerblue')
lines(1:nrow(tfidf_scores),tfidf_scores$tdif, lwd=2, col='orange')
