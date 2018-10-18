#Function that assess periods where a price change occured and there was NOT a price change in the period prior
#Chg_sum looks at the summation of price change flags for the current period and the period prior 
#(i.e., 0 = no change this period or the one before, 1 = change this period and not the one before, 2 = change this period and last)
#Dataframe only includes changes that occured in the current period, so chg_sum = 1 cannot be no change after a price change
#Count the number of times the period before the price change estimated the correct direction 
import pandas as pd
import numpy as np

def state_dependent_accuracy(change, change_sum, lag_reset_ml, lag_rest_linear, lag_act, act):
    working_mat2 = pd.DataFrame({'chg': change, 'chg_sum': change_sum, 'lag_reset_ml': lag_reset_ml, 'lag_rest_linear': lag_rest_linear, 'lag_act': lag_act, 'act': act})                  
    working_mat2 = working_mat2[(working_mat2.chg == 1) & (working_mat2.chg_sum == 1)] 
    
    ####Machine Learning

    if np.where(working_mat2.lag_act > working_mat2.act, 1, 0).sum() > 0:
        ml_accuracy_decrease = np.where(((working_mat2.lag_act > working_mat2.lag_reset_ml) & (working_mat2.lag_act > working_mat2.act)), 1, 0).sum()/np.where(working_mat2.lag_act > working_mat2.act, 1, 0).sum()
        avg_mag_ml_decrease = np.nanmean(np.where(((working_mat2.lag_act > working_mat2.lag_reset_ml) & (working_mat2.lag_act > working_mat2.act)), (working_mat2.lag_reset_ml-working_mat2.lag_act), np.nan))
    else:
        ml_accuracy_decrease = np.nan
        avg_mag_ml_decrease = np.nan
    
    if np.where(working_mat2.lag_act < working_mat2.act, 1, 0).sum() > 0:
        ml_accuracy_increase = np.where(((working_mat2.lag_act < working_mat2.lag_reset_ml) & (working_mat2.lag_act < working_mat2.act)), 1, 0).sum()/np.where(working_mat2.lag_act < working_mat2.act, 1, 0).sum()
        avg_mag_ml_increase = np.nanmean(np.where(((working_mat2.lag_act < working_mat2.lag_reset_ml) & (working_mat2.lag_act < working_mat2.act)), (working_mat2.lag_reset_ml-working_mat2.lag_act), np.nan))
    else:
        ml_accuracy_increase = np.nan
        avg_mag_ml_increase = np.nan
        
    ml_array = np.array((ml_accuracy_decrease, avg_mag_ml_decrease, ml_accuracy_increase, avg_mag_ml_increase))
        
    ######Linear
    if np.where(working_mat2.lag_act > working_mat2.act, 1, 0).sum() > 0:
        mean_accuracy_decrease = np.where(((working_mat2.lag_act > working_mat2.lag_rest_linear) & (working_mat2.lag_act > working_mat2.act)), 1, 0).sum()/np.where(working_mat2.lag_act > working_mat2.act, 1, 0).sum()
        avg_mag_mean_decrease = np.nanmean(np.where(((working_mat2.lag_act > working_mat2.lag_rest_linear) & (working_mat2.lag_act > working_mat2.act)), (working_mat2.lag_rest_linear-working_mat2.lag_act), np.nan))
        #Remove data errors
        if avg_mag_mean_decrease < -1.1:
            avg_mag_mean_decrease = np.nan
    else:
        mean_accuracy_decrease = np.nan
        avg_mag_mean_decrease = np.nan
    
    if np.where(working_mat2.lag_act < working_mat2.act, 1, 0).sum() > 0:
        mean_accuracy_increase = np.where(((working_mat2.lag_act < working_mat2.lag_rest_linear) & (working_mat2.lag_act < working_mat2.act)), 1, 0).sum()/np.where(working_mat2.lag_act < working_mat2.act, 1, 0).sum()
        avg_mag_mean_increase = np.nanmean(np.where(((working_mat2.lag_act < working_mat2.lag_rest_linear) & (working_mat2.lag_act < working_mat2.act)), (working_mat2.lag_rest_linear-working_mat2.lag_act), np.nan))
        #Remove data errors
        if avg_mag_mean_increase > 1.1:
            avg_mag_mean_increase = np.nan
    else:
        mean_accuracy_increase = np.nan
        avg_mag_mean_increase = np.nan
    
    mean_array = np.array((mean_accuracy_decrease, avg_mag_mean_decrease, mean_accuracy_increase, avg_mag_mean_increase ))
            
    return np.concatenate((ml_array, mean_array))