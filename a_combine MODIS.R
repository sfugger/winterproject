setwd("D:/sfugger/Data/")

library(foreach)
library(doSNOW)
library(gdalUtils)
library(raster)
library(rgdal)
library(SpaDES)

cshp=readOGR('D:/sfugger/Data/wider austria.shp','wider austria')
lcccrs <- CRS("+proj=lcc +lat_1=49 +lat_2=46 +lat_0=47.5 +lon_0=13.33333333333333 +x_0=400000 +y_0=400000 +ellps=GRS80 +units=m +no_defs") #for a different projection, please change the crs string accordingly
proj4string(cshp) <- lcccrs


dem<-raster("D:/sfugger/Data/eu_dem_500.tif")
proj4string(dem) <- lcccrs
crop_dem<-mask(crop(dem, cshp),cshp)
plot(crop_dem, col=topo.colors(20))


data<-read.table("D:/sfugger/Data/modis_images/MODcomb.txt") #please change the path and filename

for (inp in seq(11, nrow(data), by=2)){
  MODIS1<-paste("D:/sfugger/Data/modis_images/",data[inp,1], sep="")
  sds<-get_subdatasets(MODIS1)
  gdal_translate(sds[1], dst_dataset = "mod1.grd",of="GSBG",a_srs='+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_def')
  r1<-raster("mod1.grd")
  
  MODIS2<-paste("D:/sfugger/Data/modis_images/",data[(inp+1),1], sep="")
  sds<-get_subdatasets(MODIS2)
  gdal_translate(sds[1], dst_dataset = "mod2.grd",of="GSBG",a_srs='+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_def')
  r2<-raster("mod2.grd")

 
  comb <- mergeRaster(c(r1,r2))
 
  
  combproj <- projectRaster(comb, crop_dem, crs=lcccrs,method="ngb",res=500)
  
  name <- substring(MODIS1, first=39, last = 45) 
  mergedimage <- writeRaster(combproj, filename=paste("D:/sfugger/Data/combined_images/",name, sep=""), format="raster", overwrite=TRUE)
  
}

#plot(mergedimage,col=topo.colors(20))
#plot(comb,col=topo.colors(20))
#plot(r1,col=topo.colors(20))
