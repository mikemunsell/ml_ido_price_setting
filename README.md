# Estimating Idiosyncratic Price Setting Behavior with Machine Learning
### Mike Munsell, Brandeis University (October 2018)

In this paper, I survey a traditional econometric model for estimating optimal price setting be-
havior, and then provide intuition on how the standard model could be mapped to various machine
learning methods, including ridge regression, random forest, and KNN. Using online grocery price
data, I demonstrate that the machine learning methods show modest improvements in estimating the
direction of price changes as well as the magnitude of adjustment.

## Files

* `code/` folder contains an R script for creating the expanded competitor
price datasets, as well as python scripts for the empirical reset inflation exercise
* `data/` folder includes grocery and appliance datasets from [MIT's Billion
Prices Project](http://www.thebillionpricesproject.com/datasets/) that are expanded
in the set_data.R script. Data from the `data/expanded` folder (which is used in the
empirical reset inflation exercise) is ignored by git due to the size of the dataset
* `fig_table_notebooks/` folder contains Ipython notebooks that provide the all code 
required to reproduce the tables and figures from the manuscript.
* `manuscript/` folder contains .tex code for manuscript, as well as most recent PDF.
