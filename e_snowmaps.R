library(raster)
library(gtools)
library(tictoc)

#load dem for snow allocation
dem <- raster("D:/sfugger/Data/at_dem_500_wideclip.tif")
#load rsle maps


for (y in 2000:2000){
  imagelist <- mixedsort(sort(list.files(paste("D:/sfugger/Data/first_run_output/", y, sep = ""), pattern = ".tif", full.names = TRUE)))

#create snow maps
for (i in 1:10){
  image<-raster(imagelist[i])
  #projection of MODIS to local projection and dem extent
  lcccrs <- CRS("+proj=lcc +lat_1=49 +lat_2=46 +lat_0=47.5 +lon_0=13.33333333333333 +x_0=400000 +y_0=400000 +ellps=GRS80 +units=m +no_defs") #for a different projection, please change the crs string accordingly
  proj4string(dem) <- lcccrs
  r1proj <- projectRaster(dem, image, crs=lcccrs,method="ngb",res=500)

  snow<-200
  land<-25
  cloud<-50

  outras <- image
  outras[r1proj >= image] <-snow
  outras[r1proj < image] <-land
  outras[image==25] <-land
  outras[image==50] <- cloud

  writeRaster(outras, filename=paste("D:/sfugger/Data/first_run_outsnow/", substring(imagelist[i], first = 34, last = 37),"/", substring(imagelist[i], first = 39, last = 45),"_snow", sep=""), format="GTiff", overwrite=TRUE)
}

#image output with timestamp for video creation
snowimage <- mixedsort(sort(list.files(paste("D:/sfugger/Data/first_run_outsnow/", y, sep=""), pattern = ".tif", full.names = TRUE)))

#get date
fun<- function(x) substring(x, first = 40, last = 46)
names <- lapply(snowimage,fun)
p <- strptime(names, format="%Y%j", tz="UTC")

breakpoints <- c(20,30,60,210)
colors <- c("green","darkgrey","cyan1" )


#plot images with date stamp for GIF creation
for (i in 1:length(snowimage)){
  outras <- raster(snowimage[i])
  png(filename=paste("D:/sfugger/Data/first_run_images/",y,"/", names[i], ".png", sep=""))
  plot(outras,breaks=breakpoints,col=colors)
  text(340000, y = 375000, labels = p[i])
  dev.off()
}#end images with timesteps


}#end year

#proceed GIF creation with ImageMagick



