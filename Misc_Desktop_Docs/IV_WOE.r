# install.packages("InformationValue")
# install.packages("corrplot")
# install.packages("plyr")
# install.packages("ROCR")
# install.packages("dummies")
# install.packages("smbinning")


library(InformationValue)
library(corrplot)
library(plyr)
library(ROCR)
library(dummies)
library(smbinning)
library(car)

bnk=read.csv("C:\\Users\\amoitra\\Desktop\\Anindya\\Data Science Bootcamp\\003.Logistic Regression & Moving beyond Linearity\\Sample dataset\\bank-full.csv")


#Exploratory Data Analysis
str(bnk)
summary(bnk)
sapply(bnk, class)

#Visualize
boxplot(bnk$age, main="Boxplot of Age",ylab="Value",xlab="Age", col="blue")

boxplot(bnk$age~bnk$y, main=" AGE",ylab="age of customers",xlab="y")
boxplot(bnk$balance~bnk$y, main=" BALANCE",ylab="Balance of customers",xlab="y")
boxplot(bnk$campaign~bnk$y, main="NUM CONTACTS",ylab="number of contacts",xlab="y")
boxplot(bnk$pdays~bnk$y, main=" Previous DAYS",ylab="Previous days of contact",xlab="y")
boxplot(bnk$previous~bnk$y, main=" Previous Contacts",ylab="Previous Contacts with customers",xlab="y")
hist(bnk$age, col = "light blue", freq = FALSE)
hist(bnk$pdays,col="yellow",xlab="Previous Days of contacts",main="PDays")
hist(bnk$balance,breaks=100,col="red",xlab="BALANCE",main="BALANCE")
summary(bnk$balance)

barplot(table(bnk$housing),col="red",main="Housing Loan")
barplot(table(bnk$job),col="blue",main="JOB")
#outliers
outlr=data.frame(boxplot.stats(bnk$balance)$out)
nrow(outlr)

#outlier treatment
summary(bnk$balance)
qnt <- quantile(bnk$balance, probs=c(.25, .75), na.rm = T)
caps <- quantile(bnk$balance, probs=c(.01, .99), na.rm = T)
H <- 1.5 * IQR(bnk$balance, na.rm = T)

bnk$balance<- ifelse(bnk$balance< (qnt[1] - H),bnk$balance==caps[1], bnk$balance)
bnk$balance<- ifelse(bnk$balance> (qnt[2] + H),bnk$balance==caps[2], bnk$balance)
summary(bnk$balance)
bnk$balance<- ifelse(bnk$balance< 0,bnk$balance==0, bnk$balance)
summary(bnk$balance)

#missing
bnk1 = bnk[!bnk$education == "unknown",]

#Optional
#par(mfrow=c(2,2),las=2)
#boxplot( duration ~ y, data=bnk,col="blue")
#boxplot( pdays ~ y, data=bnk,col="red")
#plot( bnk$housing, bnk$y,xlab="Housing", ylab="Become Customer?", col=c("red","green"))
#plot( bnk$contact, bnk$y, xlab="Contact Type", ylab="Become Customer?", col=c("red","green"))

temp<- data.frame(bnk$age,bnk$balance,bnk$day,bnk$pdays,bnk$previous)
M <- cor(temp)
corrplot(M, method="circle")
corrplot(M, method="number")
corrplot(M, method="pie")
corrplot(M, type="upper")
corrplot.mixed(M)
table(bnk$y)/nrow(bnk)


#Create Training Data 
input_ones <- bnk[which(bnk$y == 'yes'), ]  # all 1's
input_zeros <- bnk[which(bnk$y == 'no'), ]  # all 0's
set.seed(100)  # for repeatability of samples
input_ones_training_rows <- sample(1:nrow(input_ones), 0.7*nrow(input_ones))  # 1's for training
input_zeros_training_rows <- sample(1:nrow(input_zeros), 0.7*nrow(input_ones))  # 0's for training. Pick as many 0's as 1's
training_ones <- input_ones[input_ones_training_rows, ]  
training_zeros <- input_zeros[input_zeros_training_rows, ]
trainingData <- rbind(training_ones, training_zeros)  # row bind the 1's and 0's 
trainingData$newy= ifelse(trainingData$y == 'yes', 1, 0)

table(trainingData$newy)

# Create Test Data
test_ones <- input_ones[-input_ones_training_rows, ]
test_zeros <- input_zeros[-input_zeros_training_rows, ]
testData <- rbind(test_ones, test_zeros)  # row bind the 1's and 0's 
testData$newy= ifelse(testData$y == 'yes', 1, 0)

trainingData<- rename(trainingData, c("default" = "default1"))
testData<- rename(testData, c("default" = "default1"))


logitMod <- glm(newy ~ job+ marital+education+ default1+ housing+ loan+ contact+poutcome+
                  age +balance+campaign+ pdays+ previous, data=trainingData, family=binomial(link="logit"))
summary(logitMod)
anova(logitMod)
#Odds Ratios
exp(coef(logitMod ))
AIC(logitMod)
BIC(logitMod)

Train_predicted <- predict(logitMod, trainingData, type="response")  # predicted scores
Concordance(trainingData$newy, Train_predicted)

table(trainingData$newy, Train_predicted>0.6)


somersD(actuals=trainingData$newy, predictedScores=Train_predicted)

predicted <- predict(logitMod, testData, type="response")  # predicted scores
Concordance(testData$newy, predicted)

#ROCR Package
rocr_pred= prediction(Train_predicted,trainingData$newy)
rocr_perf=performance(rocr_pred,"tpr","fpr")
plot(rocr_perf,colorize=T, print.cutoffs.at=seq(0.1, by=0.1))

trainingDatanew <- dummy.data.frame(trainingData, sep = ".")
testDatanew <- dummy.data.frame(testData, sep =".")

#trainingData<- rename(trainingData, c("job.admin." = "job.admin"))
#testData<- rename(testData, c("job.admin." = "job.admin"))


logitMod2 <- glm(newy ~ age + job.admin. + job.entrepreneur +
job.housemaid	+ job.management +	job.retired	+
job.services	+ job.student +	job.technician +	job.unemployed +
marital.divorced +	marital.married	+ education.primary	+ education.secondary+
default1.yes+ 	balance +	housing.yes	+ loan.yes + contact.cellular +	contact.telephone	+
duration	+ campaign +	pdays	+ previous +	poutcome.failure +poutcome.other +
# + job.blue-collar + job.self-employed
poutcome.success, data=trainingDatanew, family=binomial(link="logit"))	
summary(logitMod2)

d.Train_predicted <- predict(logitMod2, trainingDatanew, type="response")
Concordance(trainingDatanew$newy, d.Train_predicted)

d.predicted <- predict(logitMod2, testDatanew, type="response")  
Concordance(testDatanew$newy, d.predicted)

table(trainingDatanew$newy, d.Train_predicted>0.5)

#Variable Selection via Information Value
#library(smbinning)
#The process of transforming a continuous characteristic into a finite number of intervals
#(the bins), which allows for a better understanding of its distribution and its relationship 
#with a binary variable
#Smbinning does optimal binning, which categorizes a numeric characteristic into bins for
#ulterior usage in scoring modeling. This process, also known as supervised discretization,
#utilizes Recursive Partitioning to categorize the numeric characteristic
factor_vars <- c ("job", "marital","education", "default1", "housing", "loan", "contact","poutcome")
continuous_vars <- c("age", "campaign", "pdays", "balance", "previous")


iv_df <- data.frame(VARS=c(factor_vars, continuous_vars), IV=numeric(13))   # init for IV results


# compute IV for categoricals
for(factor_var in factor_vars){
  smb <- smbinning.factor(trainingData, y="newy", x=factor_var)  # WOE table
  print(factor_var)
  print(smb)
  if(class(smb) != "character"){ # heck if some error occured
    iv_df[iv_df$VARS == factor_var, "IV"] <- smb$iv
  }
}

# compute IV for continuous vars
for(continuous_var in continuous_vars){
  smb <- smbinning(trainingData, y="newy", x=continuous_var)  # WOE table
  #print(continuous_var)
  #print(smb)
  if(class(smb) != "character"){  # any error while calculating scores.
    iv_df[iv_df$VARS == continuous_var, "IV"] <- smb$iv
  }
}

iv_df <- iv_df[order(-iv_df$IV), ]  # sort
iv_df





options(scipen = 999, digits = 2)
WOETable(X=trainingData$job, Y=trainingData$newy)
WOETable(X=trainingData$poutcome, Y=trainingData$newy)
WOETable(X=trainingData$pdays, Y=trainingData$newy)


#WOE coading
trainingData$jobwoe <- ifelse(trainingData$job=='blue-collar', -0.472298104083524,              
                        ifelse(trainingData$job=='services', -0.472298104083524,
                        ifelse(trainingData$job=='unknown', -0.244019753297276, 
                        ifelse(trainingData$job=='housemaid', -0.205210478125524,
                        ifelse(trainingData$job=='unemployed', -0.117477537551011,
                        ifelse(trainingData$job=='technician', -0.0984142120415931,
                        ifelse(trainingData$job=='admin.', -0.0801370172486146,
                        ifelse(trainingData$job=='entrepreneur', -0.00348500971844908,
                        ifelse(trainingData$job=='Self Employed', -0.00348500971844908,
                        ifelse(trainingData$job=='management', 0.0376336648743491,
                        ifelse(trainingData$job=='retired', 0.490615549228216,1.07293991442155
                        )))))))))))

trainingData$balancewoe <- ifelse(trainingData$balance <= 106, -0.193,
                           ifelse(trainingData$balance <= 910, -0.015,
                           ifelse(trainingData$balance <= 2143, 0.155,0.508
                           )))

trainingData$poutcomewoe <- ifelse(trainingData$poutcome == 'unknown', -0.253,
                           ifelse(trainingData$poutcome == 'failure', 0.065,
                           ifelse(trainingData$poutcome == 'other', 0.278, 2.483
                           )))

testData$jobwoe <- ifelse(testData$job=='blue-collar', -0.472298104083524,              
ifelse(testData$job=='services', -0.472298104083524,
ifelse(testData$job=='unknown', -0.244019753297276, 
ifelse(testData$job=='housemaid', -0.205210478125524,
ifelse(testData$job=='unemployed', -0.117477537551011,
ifelse(testData$job=='technician', -0.0984142120415931,
ifelse(testData$job=='admin.', -0.0801370172486146,
ifelse(testData$job=='entrepreneur', -0.00348500971844908,
ifelse(testData$job=='Self Employed', -0.00348500971844908,
ifelse(testData$job=='management', 0.0376336648743491,
ifelse(testData$job=='retired', 0.490615549228216,1.07293991442155
)))))))))))

testData$balancewoe <- ifelse(testData$balance <= 106, -0.193,
ifelse(testData$balance <= 910, -0.015,
ifelse(testData$balance <= 2143, 0.155,0.508
)))

testData$poutcomewoe <- ifelse(testData$poutcome == 'unknown', -0.253,
ifelse(testData$poutcome == 'failure', 0.065,
ifelse(testData$poutcome == 'other', 0.278, 2.483
)))


logitMod3 <- glm(newy ~ jobwoe+ marital+education+ default1+ housing+ loan+ contact+poutcomewoe+
                  age +balancewoe+campaign+ pdays+ previous, data=trainingData, family=binomial(link="logit"))
summary(logitMod3)

woe.Train_predicted <- plogis(predict(logitMod3, trainingData))
Concordance(trainingData$newy, woe.Train_predicted)

woe.Test_predicted <- plogis(predict(logitMod3, testData))  # predicted scores
Concordance(testData$newy, woe.Test_predicted)

table(trainingData$newy, woe.Train_predicted>0.5)

#ROCR Package
rocr_pred= prediction(woe.Train_predicted,trainingData$newy)
rocr_perf=performance(rocr_pred,"tpr","fpr")
plot(rocr_perf,colorize=T, print.cutoffs.at=seq(0.1, by=0.1))

table(trainingData$newy, woe.Train_predicted>0.55)

sens_table <- optimalCutoff(actuals = trainingData$newy, predictedScores = woe.Train_predicted,                             
                                 optimiseFor = "Both", returnDiagnostics = TRUE)

sens_table <- optimalCutoff(actuals = trainingDatanew$newy, predictedScores = d.Train_predicted, 
                            optimiseFor = "Both", returnDiagnostics = TRUE)
#Cutoff for model1
optCutOff = optimalCutoff(actuals = trainingData$newy, predictedScores = Train_predicted)
                          

#model diagnostic
vif(logitMod3)

#KS STatistic
ks_stat(actuals=trainingData$newy, predictedScores=Train_predicted)
ks_stat(actuals=testData$newy, predictedScores=predicted)
#KS Plot
ks_plot(actuals=testData$newy, predictedScores=predicted)


