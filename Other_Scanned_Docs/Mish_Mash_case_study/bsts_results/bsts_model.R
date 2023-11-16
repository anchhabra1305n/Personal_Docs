library(bsts)
train_data_from_test = read.csv(file.choose(),header = T)
test_data_from_test = read.csv(file.choose(),header = T)

eq = ts(train_data_from_test$EQ,start = c(2016,1,1),end = c(2018,06,30), frequency = 13)
eq
plot(eq)

ll_ss = list()
ll_ss = AddLocalLevel(state.specification = ll_ss, y = eq)
ll_ss

ll_fit = bsts(eq,state.specification = ll_ss,niter = 1000)
ll_fit
plot(ll_fit)

##residuals plot
plot(ll_fit,'residuals',main = 'residuals')

##prediction plot
ll_pred= predict(ll_fit,horizon = 6)
plot(ll_pred,plot.original = 50)
ll_pred
median_prediction_simple_model = as.data.frame(ll_pred$median)
write.csv(median_prediction_simple_model,"model1_med_pred_1st_model.csv")
## 1st of model doing a bad job

##Add local linear trend model
llt_ss = list()
llt_ss = AddLocalLinearTrend(state.specification = llt_ss,y = eq)

llt_fit = bsts(eq,state.specification = llt_ss,niter = 1000)

llt_pred = predict(llt_fit,horizon = 6)
plot(llt_pred)
## A better job then only local level


##Add local level trend and seasonality
lts_ss = list()
lts_ss = AddLocalLinearTrend(lts_ss,y=eq)
lts_ss = AddSeasonal(lts_ss,eq,nseasons = 13)
lts_fit = bsts(eq,state.specification = lts_ss,niter = 1000)
plot(lts_fit,"components")

lts_pred = predict(lts_fit,horizon = 6)
plot(lts_pred)

lts_model_pred = as.data.frame(lts_pred$median)
write.csv(lts_model_pred,"lts_model_med_pred.csv")

##Add BSTS modeling to improve the model
nseasons = 13
ss = list()
ss = AddLocalLinearTrend(ss,y = train_data_from_test$EQ)
ss = AddSeasonal(ss,train_data_from_test$EQ,nseasons = 13)

rlls_model <- bsts(EQ ~ .,
               state.specification = ss,
               niter = 1000,
               data = train_data_from_test,
               expected.model.size = 1)
plot(rlls_model,'components')
pdf( "bsts_variable_plot.pdf", width = 13, height = 10)
plot( rlls_model,'coefficients' )

dev.off()
summary(rlls_model)

##rlls_model_predictions
rlls_model_pred = predict(rlls_model,newdata = test_data_from_test,horizon = 6)

plot(rlls_model_pred,plot.original = 33)

rlls_prediction_data = as.data.frame(rlls_model_pred$median)

setwd("C:\\Users\\anchhabra\\Desktop\\Check_case_study\\bsts_results")
write.csv(rlls_prediction_data,"bsts_model_pred.csv")


##Model size 5
rlls_model <- bsts(EQ ~ .,
                   state.specification = ss,
                   niter = 1000,
                   data = train_data_from_test,
                   expected.model.size = 5)
plot(rlls_model,'components')
pdf( "bsts_variable_plot_model_size_5.pdf", width = 13, height = 10)
plot( rlls_model,'coefficients' )

##rlls_model_predictions
rlls_model_pred = predict(rlls_model,newdata = test_data_from_test,horizon = 6)

plot(rlls_model_pred,plot.original = 33)

rlls_model_pred$median

rlls_prediction_data = as.data.frame(rlls_model_pred$median)
## this is better than model size 1


##Model size 5
rlls_model <- bsts(EQ ~ .,
                   state.specification = ss,
                   niter = 1000,
                   data = train_data_from_test,
                   expected.model.size = 10)
plot(rlls_model,'components')
pdf( "bsts_variable_plot_model_size_10.pdf", width = 13, height = 10)
dev.off()
plot( rlls_model,'coefficients' )

##rlls_model_predictions
rlls_model_pred = predict(rlls_model,newdata = test_data_from_test,horizon = 6)

plot(rlls_model_pred,plot.original = 33)

rlls_model_pred$median
