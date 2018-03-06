#%% Import all packages
import pandas as pd
import numpy as np
import time

#%% Computing time
t = time.time()
        
#%% Load table with all dates, tiles, RSLE and RSL
file = 'D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\tiletab.txt'
data = pd.read_csv(file, sep=',', names=["Date", "RSLE", "RSL", "Cper", "Fper", "Tper"], parse_dates=["Date"]) #Give column names
dattile = data.sort_values(['Date']) #Sort values per tile first and then per day
dattile.set_index('Date', inplace=True) #Set index for dates for timeseries analysis     

#%% Define cloud, no decision and land values as NaN
dattile.loc[dattile['RSLE'] == 250, 'RSLE'] = np.nan #Cloud
dattile.loc[dattile['RSLE'] == 201, 'RSLE'] = np.nan #

#%% Use difference of RSLE to validate RSLEmax and NaN values
demmax = float(4249)
# Previous and after values
dattile['RSLE_previous'] = dattile['RSLE'].shift(1) #Make a column with previous values of RSLE
dattile['RSLE_after'] = dattile['RSLE'].shift(-1) #Make a column with after values of RSLE
dattile['diff_pa'] = abs(dattile['RSLE_previous'] - dattile['RSLE_after']) #Calculate the difference between previous and after
dattile['diff_pc'] = abs(dattile['RSLE'] - dattile['RSLE_previous']) #Claculate the difference between previous and current value

dattile['diff_low'] = (dattile['diff_pc'] > 1500) & (dattile['diff_pa'] < 1500) #Set to True when the difference with previous value is higher than 1500 and the difference with successive value is lower than 1500
dattile['diff_notnan'] = dattile['diff_pa'].notnull() #Set to True when the difference values is not NaN

# Change RSLE based on the columns defined above
dattile.loc[(dattile['diff_low'] == True), 'RSLE'] = np.nan #Set RSLE values to NaN when the difference is low between previous and after values
dattile.loc[(dattile['diff_notnan'] == False), 'RSLE'] = np.nan #Set RSLE values to NaN when the difference is NaN 

timeseries = pd.DataFrame(dattile[['RSLE', 'RSL', 'Cper', 'Fper', 'Tper']]) #Read only new RSLE in a new timeseries

#%% Interpolate RSLE values and set in new dataframe (no limit included)
timeseries['RSLE'] = timeseries.RSLE.interpolate(method='time')

#%% Find differences between RSLE and Cper in previous day
ts = timeseries
ts['RSLE_prev'] = ts['RSLE'].shift(1)
ts['RSLE_diff'] = abs(ts['RSLE'] - ts['RSLE_prev'])

#%% Save timeseries as table
path1 = 'D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\tiletab_int.txt'
RSLE = ts[['RSLE','RSL']]
RSLE.to_csv(path1)

path2 ='D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\tiletab_cper.txt'
cper = ts[['RSLE_diff', 'Cper']]
cper.to_csv(path2)

path3 = 'D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\tiletab_fper.txt'
fper = ts[['RSLE_diff', 'Fper']]
fper.to_csv(path3)

path4 = 'D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\tiletab_tper.txt'
tper = ts[['RSLE_diff', 'Tper']]
tper.to_csv(path4)