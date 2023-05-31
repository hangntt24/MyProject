# -*- coding: utf-8 -*-
"""
Created on Mon May 22 08:07:09 2023

@author: HANG
"""

library(magrittr)
library(dplyr)

# Sample Data for demonstration
mydata = data.frame(pred = c(0.6,0.1,0.8,0.3,0.5,0.6,0.4,0.3,0.5), 
                        y = c(1,0,1,0,1,1,0,1,0))

# Sort data in descending order of predicted prob.
mydata %<>% arrange(desc(pred))

# Cumulative % Borrowers
random = 1:length(mydata$pred)/length(mydata$pred)

# Cumulative % of Bads
cumpercentbad = cumsum(mydata$y)/sum(mydata$y)

# Calculate AR
random = c(0,random)
cumpercentbad = c(0,cumpercentbad)
idx = 2:length(cumpercentbad)
testdf=data.frame(cumpercentpop = (random[idx] - random[idx-1]), 
                  cumpercentbad = (cumpercentbad[idx] + cumpercentbad[idx-1]))
Area = sum(testdf$cumpercentbad * testdf$cumpercentpop/2)
Numerator = Area - 0.5
Denominator = 0.5*(1-mean(mydata$y))
(AR = Numerator / Denominator)

# Code tinh AR
import pandas as pd
import numpy as np

dulieuktl = pd.read_excel("C:/Users/HANG/Downloads/dulieuktl_train.xlsx")

AR_loan_amount = dulieuktl.filter(['y','loan_amount'])
AR_loan_amount = AR_loan_amount.sort_values('loan_amount')


countTotal_eachgr = AR_loan_amount.groupby('loan_amount',as_index = False).count()
countBad_eachgr = AR_loan_amount.groupby('loan_amount',as_index = False)['y'].sum()


# Cumulative % Borrowers
cumtotal_eachgr = np.cumsum(countTotal_eachgr['y'])/np.sum(countTotal_eachgr['y'])
cumtotal_eachgr.loc[-1] = 0

# Cumulative % of Bads
cumbad_eachgr = np.cumsum(countBad_eachgr['y'])/np.sum(countBad_eachgr['y'])
cumbad_eachgr.loc[-1] = 0

ar1 = []
for idx in range(0,2679):
    ar = (cumtotal_eachgr[idx] - cumtotal_eachgr[idx-1]) * (cumbad_eachgr[idx] + cumbad_eachgr[idx-1])/2

    ar1.append(ar)
    
total = 0
for i in range(0,(len(ar1)-1)):
    total = total + ar2[i]

Numerator = 0.5 - total
Denominator = 0.5 * (1-AR_loan_amount['y'].mean())
Area = Numerator/Denominator

print(Area)

    