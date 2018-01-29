#%% Import all packages
import numpy as np
import glob as glob
import gdal
import time
from natsort import natsorted
from pathlib import Path
from datetime import datetime
import rasterio
from rasterio.warp import calculate_default_transform, reproject, Resampling

#%% Computing time
t = time.time()

#%% Function for getting prijection, trasnform, eextent and resolution
def GetCRSRes(path):
    with rasterio.open(path) as src:
        dst_crs = src.crs
        dst_transform = src.affine
        dst_width = src.width
        dst_height = src.height
        dst_res = src.res
    return dst_crs, dst_transform, dst_width, dst_height, dst_res

#%% Function for setting destination projection and resolution
def SetCRSRes(srcpath, dstpath, dst_crs, dst_transform, dst_width, dst_height):
    with rasterio.open(srcpath) as src:
        transform, width, height = calculate_default_transform(
            src.crs, dst_crs, src.width, src.height, *src.bounds)
        kwargs = src.meta.copy()
        kwargs.update({
            'crs': dst_crs,
            'transform': dst_transform,
            'width': dst_width,
            'height': dst_height
    })
    
        with rasterio.open(dstpath, 'w', **kwargs) as dst:
            for i in range(1, src.count + 1):
                reproject(
                source = rasterio.band(src, i),
                destination = rasterio.band(dst, i),
                src_transform = src.affine,
                src_crs = src.crs,
                dst_transform = dst_transform,
                dst_crs = dst_crs,
                resampling = Resampling.nearest)
                
#%% Function for finding RSLE
def findRSLE(step, tiledata, moddata, demmin, demmax, nn):
    nsteps = np.floor((demmax-demmin)/(step)).astype(int)
    demdif = np.linspace(demmin, demmax, nsteps)
    
    A = nn #Total amount is equal to the amount without NAN values
    I = np.array([])
    h = np.array([])
    
    for elev in demdif: #Count snow pixels below RSLE
        tmp_h = (tiledata >= elev).astype(float) #Float matrix for defining amount of higher pixels
        tmp_l = (tiledata <= elev).astype(float) #Float matrix for defining amount of lower pixels
        tmp_h[tmp_h == 0] = np.nan #Returns zero values in tmp_h to np.nan
        tmp_l[tmp_l == 0] = np.nan #Returns zero values in tmp_l to np.nan
        
        values_h = tmp_h*moddata #Get moddata values above RSLE
        values_l = tmp_l*moddata #Get moddata values below RSLE
        
        nss = np.sum((values_l <= snow) & (values_l > land)) #Counts snow pixels below RSLE  
        nll = np.sum(values_h == 0) #Counts land pixels above RSLE

        Esum = nss + nll #Sum of snow and land pixels

        I = np.append(I, Esum) #I is the matrix with Esum values
        h = np.append(h, elev)
            
    RSLEsum = (I.min()).astype(int) #Finds the lowest sum of snow and land pixels
        
    RSL = (RSLEsum/A)*100 #Get RSL as the percentage of RSLEsum over the area
    pos = h[np.where(I == RSLEsum)] #Gets the corresponding elevation
    RSLE = pos[-1] #Gets the last element (important when RSLEsum == 0)
    
    return RSLE, RSL

#%% Function to set date to integer
def datetoint(dt_time):
    return 10000*dt_time.year + 100*dt_time.month + dt_time.day

#%% Making a list of MODIS .tif files (from A_Reprojecting and cropping MODIS.py) and a path to the DEM
list1 = natsorted(glob.glob(r'D:\Archive\2017-2018\Thesis\Data\MODIS MOD10A1\Cropped data\*.tif'))
dempath = r'D:\Archive\2017-2018\Thesis\Data\GMTED2010\GMTED2010_EPSG3310_cropped_demres.tif'

#%% MODIS output values for testing
land = 0 #land is actually lower or equal than 10
snow = 100 #snow is actually between 10-100
missing = 200
nodecision = 201
night = 211
inlandwater = 237
ocean = 239
cloud = 250
detectorsaturated = 254
fill = 255

#%% For loop to create RSLE arrays per date and tile
# Create empty array to fill
b = []

for i in range(len(list1)):
    tic = time.time()
    modpath = list1[i] 
    tilepath = dempath

    #Get observation date and write in table
    mod = gdal.Open(modpath)
    dt_time = datetime.strptime(mod.GetMetadataItem('RANGEENDINGDATE'),"%Y-%m-%d")
    date = datetoint(dt_time)
    mod = None

    #Open DEM tile and get projection and resolution
    tile_crs, tile_transform, tile_width, tile_height, res = GetCRSRes(tilepath)

    #Define paths and names
    p1 = Path(list1[i])
    n1 = p1.stem
    p2 = dempath
    name = str(n1)
        
    # Read MOD raster as array
    with rasterio.open(modpath) as mod:
        moddata = mod.read(1).astype(float)
        moddata[moddata == fill] = np.nan #Set fill values to NAN
        
        # Count number of data, false data, snow data, water body data and land data
        nn = np.count_nonzero(~np.isnan(moddata)) #Counts total non NAN pixels
        nc = np.sum(moddata == cloud) #Counts cloud pixels
        nf = np.sum([np.sum(moddata == missing), 
                     np.sum(moddata == nodecision), 
                     np.sum(moddata == night),  
                     np.sum(moddata == detectorsaturated),
                     np.sum(moddata == inlandwater),
                     np.sum(moddata == ocean)]) #Counts false pixels
        ns = np.sum((moddata <= snow) & (moddata > land)) #Counts snow pixels
        nl = np.sum(moddata == land) #Counts land pixels
        
        # Calculate false and cloud pixel percentage
        cper = nc/nn
        fper = nf/nn
        
        #Proceed only if cloud pixel amount does not exceed threshold
        if cper >= 0.7:
            RSLE = cloud
            RSL = np.nan
            b.append([date, RSLE, RSL])
            continue
        # Proceed only if false pixel amount does not exceed threshold
        if fper >= 0.7:
            RSLE = nodecision
            RSL = np.nan
            b.append([date, RSLE, RSL])
            continue

        # Read tile raster as array
        with rasterio.open(tilepath) as tile:
            tiledata= tile.read(1).astype(float)
            
            # Get min, max from DEM tile
            demmin = np.min(tiledata[np.nonzero(tiledata)])#Count nonzero values
            demmax = np.max(tiledata[np.nonzero(tiledata)])#Count nonzero values
            
            # When the snowpixels are less than 5 percent, set RSLE as demmax (this means that there is no snow present at the tile)
            if ns <= 0.01*nn:
                RSLE = demmax
                RSL = np.nan 
                b.append([date, RSLE, RSL])
                continue
            
            # Finding RSLE between demmin and demmax
            step = 10
            RSLE, RSL = findRSLE(step, tiledata, moddata, demmin, demmax, nn) #Calls function findRSLE
            b.append([date, RSLE, RSL])
    print(time.time() - tic)
     
#%% Write table(.txt) to folder
tablename = 'D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\tiletab.txt'
np.savetxt(tablename, b, fmt=['%.d','%4.F','%6.F'], delimiter=',', newline='\r\n')

#%% Computing time
toc = time.time()-t
print(toc)