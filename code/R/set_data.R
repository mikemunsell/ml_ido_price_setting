#######################################################################################
## Code that takes category-level pricing data from the Billion Prices Project (BPP)
## and expands it to include all competitors prices and the change in each competitors
## price since each items last price change (all interacted with the item level price
## duration) - Mike Munsell, Brandeis University
#######################################################################################

#Read required packages
library(reshape2)
require(data.table)

#product = 1 is for grocery
#product = 2 is for household appliances (used for validation)
product = 1

#exercise = 1 is for prediction exercise (price changes only)
#exercise = 2 is for reset inflation (observed price changes and no price changes)
exercise = 1

#Set working directory and read in data to compile
getwd()
setwd("../../data")
files <- list.files(getwd(), pattern ="*.csv")

#Grocery files
if(product == 1){
  files = files[-length(files)]
}

#Household appliances (validation) file
if(product == 2){
  files = files[lenght(files)]
}

#chg_dataset => expands RHS of observed price change data to include all competitors prices just before a price change
chg_dataset <- function(dataframe) {
  
  comp_vars <- c('date', 'lp_na_lag', 'id')
  temp_data <- data.table(dataframe[, comp_vars])
  #For now, just include price, not duration
  temp_data <- dcast(temp_data, date ~ id, value.var = c("lp_na_lag"))
  #If price is missing in temp_data, set to zero. This means that the item wasn't available
  temp_data[is.na(temp_data)] <- 0
  colnames(temp_data)[-1] <- paste("lp_na_lag", colnames(temp_data)[-1], sep = "_")
  inc_cols1 = names(temp_data)[-1]
  #Merge into larger dataframe so each item/date has the competitor's prices
  data <- merge(dataframe, temp_data,by="date")
  #Merge in competitors prices at the time of last change (tau)
  colnames(temp_data)[colnames(temp_data)=="date"] <- "tau"
  colnames(temp_data)[-1] <- paste("tau", colnames(temp_data)[-1], sep = "_")
  inc_cols2 = names(temp_data)[-1]
  data <- merge(data, temp_data, by="tau")
  #Create log change variable from the last time the price changed
  ids <- unique(data$id)
  
  for (i in ids){
    date_var <- c(paste("lp_na_lag_", i, sep=""))
    tau_var <- c(paste("tau_lp_na_lag_", i, sep=""))
    data[tau_var] <- log(data[date_var]/data[tau_var])
  }

  #Replace all nans with zeros since the price  didn't exist yet
  data[is.na(data)] <- 0
 
  #Take competitors prices and multiply by good's duration
  #Subset competitors prices (zeroed for additional version of your own price)
  competitors_one <- data[, inc_cols1]
  colnames(competitors_one) <- paste("og", colnames(competitors_one), sep = "_")
  competitors_oneandtwo <- data[, c(inc_cols1, inc_cols2)]
  duration <- data[, c('inv_sqrt_duration_lag')]
  #Set inv_sqrt_duration_lag to zero if it is missing (this means that the duration before was zero)
  duration[is.na(duration)] <- 0
  datesANDid <- data[, c('date', 'id')]
  competitors.ido <- competitors_oneandtwo*duration
  competitors.ido <- cbind(datesANDid, competitors.ido)
  data_2 <- merge(dataframe, competitors.ido, by=c("date", "id"))
  competitors_one <- cbind(datesANDid, competitors_one)
  data_final <- merge(data_2, competitors_one, by=c("date", "id") )
  remove(data, data_2, competitors_one, competitors_oneandtwo, competitors.ido, duration, inc_cols1, temp_data, datesANDid)
  
  #Set own price lag to zero (already captured)
 for (i in ids){
   var_names <- c(paste("lp_na_lag_", i, sep=""), paste("tau_lp_na_lag_", i, sep=""), paste("og_lp_na_lag_", i, sep=""))
   data_final[data_final$id == i, var_names] <- 0
   }
  
  #Leave only lag variables
  drop_list <- c( "X", "rid_id", "cat_url","lp_na", "prcs_a_lag", "duration_lag", "bppcat", "miss", "price0", "price", "nsprice", "sale", 
                  "fullprice", "fullsale", "initialspell", "lastspell", "retailer", 
                  "prc_b", "indexcpi", "indexps", "indexcpi_tau", "indexps_tau", "indpro", 
                  "indpro_tau", "prcs_a", "lduration_lag", "p_na",
                  "tau_num", "duration", "sqrt_duration", "inv_sqrt_duration", "chg_p", "chg_p2", "chg_indpro",
                  "chg_rs", "chg_pmi", "chg_cons", "chg_orders", "chg_expect", "cons", "rs", "pmi", "orders", "expect", "cons_tau", "rs_tau", "pmi_tau", "orders_tau", "expect_tau",
                  'd0', 'd1', 'd2','d3','d4','d5','d6','d7','d8','d9','d10','d11','d12','d13','d14','d15','d16','d17','d18','d19','d20','d21','d22', 'd23')
  
  #Use the price before the change to train a model using current price on the test set
  data_final <- data_final[,!(names(data_final) %in% drop_list)]

  #For any variable that is missing, it is because there wasn't price data then, so drop if lp_na_lag is zero (first obs)
  completeVec <- complete.cases(data_final[, 'lp_na_lag'])
  data_final <- data_final[completeVec, ]
  data_final <- data.table(data_final)
  invisible(lapply(names(data_final),function(.name) set(data_final, which(is.infinite(data_final[[.name]])), j = .name,value =0)))
  
  #Get last price change % 
  tau_change <- dataframe[dataframe$chg == 1, c('date', 'dlprcs_a', 'id')]
  colnames(tau_change)[colnames(tau_change)=="date"] <- "tau"
  colnames(tau_change)[colnames(tau_change)=='dlprcs_a'] <- 'dlprcs_a_lst'
  data_final <- merge(data_final, tau_change, by=c("tau", "id"))
  
  #Take out lag so that I can merge with non-lag (if reset exercise)
  if(exercise == 2){
    names(data_final) <- gsub(x = names(data_final), pattern = "_lag", replacement = "")  
  }
  
  return(data_final)
}

#no_chg_dataset => expands RHS of constant price data to include all competitors prices the period before
no_chg_dataset <- function(dataframe) {
  
  comp_vars <- c('date', 'lp_na', 'id')
  temp_data <- data.table(dataframe[, comp_vars])
  #For now, just include price, not duration
  temp_data <- dcast(temp_data, date ~ id, value.var = c("lp_na"))
  #If price is missing in temp_data, set to zero. This means that the item wasn't available
  temp_data[is.na(temp_data)] <- 0
  colnames(temp_data)[-1] <- paste("lp_na", colnames(temp_data)[-1], sep = "_")
  inc_cols1 = names(temp_data)[-1]
  #Merge into larger dataframe so each item/date has the competitor's prices
  data <- merge(dataframe, temp_data,by="date")
  #Merge in competitors prices at the time of last change (tau)
  colnames(temp_data)[colnames(temp_data)=="date"] <- "tau"
  colnames(temp_data)[-1] <- paste("tau", colnames(temp_data)[-1], sep = "_")
  inc_cols2 = names(temp_data)[-1]
  data <- merge(data, temp_data, by="tau")
  #Create log change variable from the last time the price changed
  ids <- unique(data$id)
  
  for (i in ids){
    date_var <- c(paste("lp_na_", i, sep=""))
    tau_var <- c(paste("tau_lp_na_", i, sep=""))
    data[tau_var] <- log(data[date_var]/data[tau_var])
  }
  
  #Replace all nans with zeros since the price  didn't exist yet
  data[is.na(data)] <- 0

  #Take competitors prices and multiply by good's duration
  #Subset competitors prices (zeroed for additional version of your own price)
  competitors_one <- data[, inc_cols1]
  colnames(competitors_one) <- paste("og", colnames(competitors_one), sep = "_")
  competitors_oneandtwo <- data[, c(inc_cols1, inc_cols2)]
  duration <- data[, c('inv_sqrt_duration')]
  #Set inv_sqrt_duration_lag to zero if it is missing (this means that the duration before was zero)
  duration[is.na(duration)] <- 0
  datesANDid <- data[, c('date', 'id')]
  competitors.ido <- competitors_oneandtwo*duration
  competitors.ido <- cbind(datesANDid, competitors.ido)
  data_2 <- merge(dataframe, competitors.ido, by=c("date", "id"))
  competitors_one <- cbind(datesANDid, competitors_one)
  data_final <- merge(data_2, competitors_one, by=c("date", "id") )
  remove(data, data_2, competitors_one, competitors_oneandtwo, competitors.ido, duration, inc_cols1, temp_data, datesANDid)
  
  #Set own price lag to zero (already captured)
  for (i in ids){
    var_names <- c(paste("lp_na_", i, sep=""), paste("tau_lp_na_", i, sep=""), paste("og_lp_na_", i, sep=""))
    data_final[data_final$id == i, var_names] <- 0
  }
  
 
  drop_list <- c( "X", "rid_id", "lp_na_lag", "cat_url", "prcs_a_lag", "duration_lag", "bppcat", "miss", "price0", "price", "nsprice", "sale", 
                  "fullprice", "fullsale", "initialspell", "lastspell", "retailer", 
                  "prc_b", "indexcpi", "indexps", "indexcpi_tau", "indexps_tau", "indpro", 
                  "indpro_tau", "prcs_a", "lduration_lag", "p_na",
                  "tau_num", "duration", "sqrt_duration_lag", "inv_sqrt_duration_lag", "chg_p_lag", "chg_p2", "chg_indpro_lag",
                  "chg_rs_lag", "chg_pmi_lag", "chg_cons_lag", "chg_orders_lag", "chg_expect_lag", "cons", "rs", "pmi", "orders", "expect", "cons_tau", "rs_tau", "pmi_tau", "orders_tau", "expect_tau",
                  'd0_lag', 'd1_lag', 'd2_lag','d3_lag','d4_lag','d5_lag','d6_lag','d7_lag','d8_lag','d9_lag','d10_lag','d11_lag','d12_lag','d13_lag','d14_lag','d15_lag','d16_lag','d17_lag','d18_lag','d19_lag','d20_lag','d21_lag','d22_lag', 'd23_lag')
  
  #Use the price before the change to train a model using current price on the test set
  data_final <- data_final[,!(names(data_final) %in% drop_list)]
  
  #For any variable that is missing, it is because there wasn't data then, so drop if lp_na_lag is zero (first obs)
  completeVec <- complete.cases(data_final[, 'lp_na'])
  data_final <- data_final[completeVec, ]
  data_final <- data.table(data_final)
  invisible(lapply(names(data_final),function(.name) set(data_final, which(is.infinite(data_final[[.name]])), j = .name,value =0)))
  
  #Get last price change % 
  tau_change <- dataframe[dataframe$chg == 1, c('date', 'dlprcs_a', 'id')]
  colnames(tau_change)[colnames(tau_change)=="date"] <- "tau"
  colnames(tau_change)[colnames(tau_change)=='dlprcs_a'] <- 'dlprcs_a_lst'
  data_final <- merge(data_final, tau_change, by=c("tau", "id"))
  
  return(data_final)
}



if(exercise == 1){
for (f in 1:length(files)){
  file = paste(getwd(), files[f], sep="/")
  all_cat_data <- read.csv(file)
  chg_data <- chg_dataset(all_cat_data)
  chg_data <- chg_data[chg_data$chg == 1, ]
  write.table(cat_data, file = paste(getwd(), "/expanded/", files[f], sep=""), sep = ",", row.names = FALSE)
  rm(chg_data, all_cat_data)
}
}

#Combine all food products for reset inflation analysis
if((exercise == 2) & (product = 1)){
    file1 = paste(datapath, files[1], sep="/")
    file2 = paste(datapath, files[2], sep="/")
    file3 = paste(datapath, files[3], sep="/")
    file4 = paste(datapath, files[4], sep="/")
    file5 = paste(datapath, files[5], sep="/")
    file6 = paste(datapath, files[6], sep="/")
    file7 = paste(datapath, files[7], sep="/")
    file8 = paste(datapath, files[8], sep="/")
    cat1 <- read.csv(file1)
    cat2 <- read.csv(file2)
    cat3 <- read.csv(file3)
    cat4 <- read.csv(file4)
    cat5 <- read.csv(file5)
    cat6 <- read.csv(file6)
    cat7 <- read.csv(file7)
    cat8 <- read.csv(file8)
    all_cat_data <- rbind(cat1,cat2,cat3,cat4,cat5,cat6,cat7,cat8)
    chg_data <- chg_dataset(all_cat_data)
    chg_data <- chg_data[chg_data$chg == 1, ]
    no_chg_data <- no_chg_dataset(all_cat_data)
    no_chg_data <- no_chg_data[no_chg_data$chg == 0, ]
    cat_data <- rbind(chg_data, no_chg_data)
    write.table(cat_data, file = paste(getwd(), "/expanded/cat11.csv", sep=""), sep = ",", row.names = FALSE)
    rm(no_chg_data, chg_data, all_cat_data)
  }

if((exercise == 2) & (product = 2)){
    file = paste(getwd(), files, sep="/")
    all_cat_data <- read.csv(file)
    chg_data <- chg_dataset(all_cat_data)
    chg_data <- chg_data[chg_data$chg == 1, ]
    no_chg_data <- no_chg_dataset(all_cat_data)
    no_chg_data <- no_chg_data[no_chg_data$chg == 0, ]
    cat_data <- rbind(chg_data, no_chg_data)
    write.table(cat_data, file = paste(getwd(), "/expanded/cat531.csv", sep=""), sep = ",", row.names = FALSE)
    rm(no_chg_data, chg_data, all_cat_data)
  }
