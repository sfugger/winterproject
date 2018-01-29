#%% Import all packages
import gdal
import ogr
import time
import numpy as np
import glob as glob
from pathlib import Path

#%% Start computing time
t = time.time()

#%% Import the catchment(.shp) and get layers, spatial reference and the extent (bounding box)
catch1 = r"D:\Archive\2017-2018\Thesis\Data\MOPEX\Catch_11213500\catch_11213500_EPSG3310.shp"
driver = ogr.GetDriverByName('ESRI Shapefile')
catch1 = driver.Open(catch1, 0)
layer = catch1.GetLayer()

offset = 5000
minX, maxX, minY, maxY = layer.GetExtent()
bbox = (np.floor(minX-offset), np.ceil(maxY+offset), np.ceil(maxX+offset), np.floor(minY-offset))

#%% Making a list of MODIS .hdf files

list1=glob.glob(r'D:\Archive\2017-2018\Thesis\Data\MODIS MOD10A1\Data\*.hdf')

#%% Read MODIS data subdatasets for the list, reproject and crop to bbox extent

for i in range(len(list1)):
    file = list1[i]
    p = Path(list1[i])
    name = p.stem
    ds = gdal.Open(list1[i])
    sds = gdal.Open(ds.GetSubDatasets()[0][0])
    path1 = 'D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\Translated data\\' + str(name) + '.tif'
    path2 = 'D:\\Archive\\2017-2018\\Thesis\\Data\\MODIS MOD10A1\\Cropped data\\' + str(name) + '.tif'
    sds_trans = gdal.Warp(path1, sds, dstSRS='EPSG:3310')
    sds_crop = gdal.Translate(path2, sds_trans, projWin=bbox)
    #Close rasters
    sds_trans = None
    sds_crop = None

#%% Computing end time(seconds)
elapsed = time.time() - t
print(elapsed)