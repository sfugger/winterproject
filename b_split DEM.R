setwd("D:/sfugger/Data/")

#install when needed and load libraries
library(raster)
library(SpaDES)
library(gtools)

#read prepared dem (thickened border)
dem<-raster("D:/sfugger/Data/at_dem_500.tif")
par(mar = rep(2,4))
#check the dem
plot(dem, col=topo.colors(20))


#if only selected region for test purpose
#newext <- c(330000,390000, 370000, 430000)
#testregion <- crop(dem, newext)
#plot(testregion, col=topo.colors(20))

#split dem into ~20x20 (variable) pixels
nx<-floor(ncol(dem)/30)
ny<-floor(nrow(dem)/30)

#split testregion
#nx<-floor(ncol(testregion)/30)
#ny<-floor(nrow(testregion)/30)
#splitRaster(testregion,nx,ny, path=("D:/sfugger/Data/testregion_tiles"))

splitRaster(dem,nx,ny, path=("D:/sfugger/Data/split_tiles_3030"))


#check for NA with threshold
list <- mixedsort(sort(list.files(path="D:/sfugger/Data/split_tiles_3030", pattern=".grd", all.files=FALSE,
           full.names=FALSE)))

x<-vector()
for (i in 1:length(list)) {
  tile <- raster(paste("D:/sfugger/Data/split_tiles_3030/", list[i],sep=""))
  check=freq(tile, value=NA)/ncell(tile)
  
  if(check <= 0.1) {
    x<- c(x,list[i])
    writeRaster(tile, filename=paste("D:/sfugger/Data/first_run_tiles/",list[i], sep=""), "GTiff", overwrite=TRUE)
  }
  
}
write(x, "D:/sfugger/Data/first_run_tiles/at_tiles.txt")


#to plot single tile
#p<-raster(paste("D:/sfugger/Data/at_dem_500/", x[1000], sep=""))
#plot(p,col=topo.colors(20))

#to remerge and write it...
#z<-paste("D:/sfugger/Data/at_dem_500/",x[1:length(x)], sep="")
#rasters <-lapply(z,raster)
#merge <- mergeRaster(rasters)
#plot(merge, col=topo.colors(20))
#writeRaster(merge,"remerged","GTiff", overwrite=TRUE)


#austria <- raster("D:/sfugger/Data/remerged.tif")
#plot(austria, col=topo.colors(20), add=TRUE)
#MOD <- raster("D:/sfugger/Data/combined_images/2000056.grd")
#plot(MOD, add=TRUE)
