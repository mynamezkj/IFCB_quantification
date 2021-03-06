#We have to download all the autoclass results from the IFCB dashboard for the
#testing samples

#We should generate one csv for each class with the prevalence for each
#file in columns

downloadAutoClassPrevs<-function()
{
  #First we compute the samples used for testing
  training<-read.table('../../deeplearningfeatures/training_samples.csv')
  IFCB<-readRDS('../../IFCB.RData')
  samples<-data.frame(as.character(unique(IFCB$Sample)),stringsAsFactors = FALSE)
  testing<-setdiff(samples[,1],training[,1])
  base_url<-'http://ifcb-data.whoi.edu/mvco/'
  
  #Create data.table for the results
  classes<-as.character(unique(IFCB$AutoClass))
  if (file.exists('prevs.RData'))
    prevs<-readRDS('prevs.RData')
  else
    prevs<-data.frame(matrix(0,nrow=length(testing),ncol=length(classes)))
  colnames(prevs)<-classes
  rownames(prevs)<-testing[order(testing)]
  
  for (s in 307:length(testing))
  {
    sample<-testing[s]
    csv_url<-paste0(base_url,sample,"_class_scores.csv")
    downloaded=FALSE
    while (!downloaded)
    {
      try({
        print(paste0("Downloading file for: ",sample," [",s," of ",length(testing),"]"))
        results<-read.csv(url(csv_url))    
        downloaded=TRUE
      })
    }
    print("Done. Processing...")
    cm<-results[,2:ncol(results)]
    for (i in 1:nrow(results))
    {
      winner<-which.max(cm[i,])
      cm[i,]<-0
      cm[i,winner]<-1
    }
    v<-colSums(cm)
    v<-v/sum(v)
    prevs[sample,names(v)]<-v
    saveRDS(prevs,file = "prevs.RData")
  }
}

saveToFiles<-function()
{
  #Load the data
  prevs<-readRDS('prevs.RData')
  for (c in colnames(prevs))
  {
    fileName<-paste0(c,".csv")
    d<-data.frame(AutoClass=prevs[,c])
    rownames(d)<-1:nrow(d)-1
    write.csv(file=fileName,d,quote = FALSE)
  }
}

#downloadAutoClassPrevs()
saveToFiles()