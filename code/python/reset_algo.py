#Algorithm that reads in a dataframe and lists of linear/machine learning predictors
#Items with price change are used as a training set
#Outputs predicted price change values for items without a price change 
#Dataframe needs to include date
import numpy as np

def reset_algo(df, pred_cols, ml_cols, model_lin, model_ml):
    #Train/test
    date = df.date.unique()[0]
    train = df[df.chg == 1]
    train_y = train.dlprcs_a
    train_x_lin = train[pred_cols]
    train_x_ml = train[ml_cols]
 
    test = df[(df.chg == 0)]
    test_x_lin = test[pred_cols]
    test_x_ml = test[ml_cols]

    model_lin.fit(train_x_lin, train_y)
    model_ml.fit(train_x_ml, train_y)
    
    return(np.transpose(model_ml.predict(test_x_ml)), np.transpose(model_lin.predict(test_x_lin)), \
           np.repeat(date,len(train)), np.repeat(date, len(test)), \
           test[['id', 'chg', 'lp_na']], train[['id', 'chg', 'lp_na', 'dlprcs_a']])