#Input dataframe with estimated price change (for dates wihtout a price change)
#and actual price changes (for dates with a price change)
#Follows methodology of Bils, Klenow & Malin 2012 and updates prices with their estimated
#price change during months without a price change, and to their actual price change
#when a change occurs. Outputs the resulting dataframe.
import pandas as pd
import numpy as np

def price_update(df, act_price, dates):
    working_mat = df.join(pd.DataFrame(act_price).rename(columns = {'lp_na': 'act_price'}))
    reset = np.zeros((len(dates),2))
    reset[0,0] = working_mat[working_mat.date == dates[0]].act_price
    reset[0,1] = working_mat[working_mat.date == dates[0]].act_price
    for d in range(1,len(dates)):
        change_flag = working_mat[working_mat.date == dates[d]].chg.values[0]
        start_price_ml = reset[d-1,0]
        start_price_mean = reset[d-1,1]
        if change_flag == 0:
            reset[d,0] = start_price_ml + working_mat[working_mat.date == dates[d]].dlprcs_a
            reset[d,1] = start_price_mean + working_mat[working_mat.date == dates[d]].mean_chg
        else:
            reset[d,0] = working_mat[working_mat.date == dates[d]].act_price
            reset[d,1] = working_mat[working_mat.date == dates[d]].act_price

    data_for_df = {'reset_ml': reset[:,0], 'reset_mean': reset[:,1], 'date': dates, 'chg': working_mat.chg, 'act_price': working_mat.act_price}
    reset_return = pd.DataFrame(data_for_df)
    
    return reset_return
