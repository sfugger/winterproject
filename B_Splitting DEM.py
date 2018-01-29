#%% Import all packages

import time
import rasterio 
from rasterio.warp import calculate_default_transform, reproject, Resampling
from rasterio.transform import from_bounds

#%% Computing time

tic = time.time()

#%% Function for getting projection

def GetCRSRes(path):
    with rasterio.open(path) as src:
        dst_crs = src.crs
        dst_transform = src.affine
        dst_width = src.width
        dst_height = src.height
    return dst_crs, dst_transform, dst_width, dst_height

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
                
#%% Function for getting transform, xmin, ymin, cols, rows, pixelwidth and pixelheight

def transinfo(path):
    with rasterio.open(path) as src:
        src_transform = src.affine
        src_xmin, src_ymax = (src.bounds.left, src.bounds.top)
        src_cols, src_rows = src.width, src.height
        xres, yres = src.res
    return src_transform, src_xmin, src_ymax, src_cols, src_rows, xres, -yres

#%% Paths
mod = r'D:\Archive\2017-2018\Thesis\Data\MODIS MOD10A1\Cropped data\MOD10A1.A2000055.h08v05.006.2016061160359.tif'
dem = r'D:\Archive\2017-2018\Thesis\Data\GMTED2010\GMTED2010_EPSG3310_cropped_highres.tif'
dem_new = r'D:\Archive\2017-2018\Thesis\Data\GMTED2010\GMTED2010_EPSG3310_cropped_demres.tif'

#%% Get projection and resolution from MODIS
dst_crs, dst_transform, dst_width, dst_height = GetCRSRes(mod)

#%% Set destination projection and resolution to DEM
demnew = SetCRSRes(dem, dem_new, dst_crs, dst_transform, dst_width, dst_height)

#%% Get DEM transform info
transform, xmin, ymax, cols, rows, xres, yres = transinfo(dem_new)

#%% Create array for x and y with 20x20 pixels
npixels = 20

x = []
y = []

for i in range(0, 121, npixels):
    x0 = int(xmin)
    xnew = x0 + i*xres
    x.append(xnew)
    
for j in range(0, 101, npixels):
    y0 = int(ymax)
    ynew = y0 + j*yres
    y.append(ynew)
    
#%% Loop through the created space to make tiles
pathdem = dem_new
dst_width = npixels
dst_height = npixels

for k in range(1, len(y)):
    for l in range(1, len(x)):
        # Set a file name structure and path for the tiles
        name = str(l)+str(k)
        path_tile = r"D:\Archive\2017-2018\Thesis\Data\GMTED2010\Tiles\tile_"+str(name)+".tif"
        # Get destination transform from the x and y matrix and set CRS and Res with the function
        dst_transform = from_bounds(x[l], y[k], x[l-1], y[k-1], dst_width, dst_height)
        demtile = SetCRSRes(pathdem, path_tile, dst_crs, dst_transform, dst_width, dst_height)
        
#%% Computing time
toc = time.time() - tic
print(toc)