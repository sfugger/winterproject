setwd("D:/sfugger/Data/Rcode")

library(tictoc)
library(foreach)
library(doSNOW)
library(gdalUtils)
library(raster)
library(rgdal)
library(SpaDES)
library(gtools)

#read list of combined and reprojected MODIS images, combination and reprojection happened in other script
data <-read.table("D:/sfugger/Data/combined_images/images.txt")

#read list of files of dem-regions, region split in other script
tileslist <- mixedsort(sort(list.files("D:/sfugger/Data/first_run_tiles", pattern = ".tif", full.names = TRUE)))

#if not there already
#dir.create("D:/sfugger/Data/testregion_tiles_tables")
#create a table each tile later containing rsle and rsl for each day

#for (n in 1:length(tileslist)) {
#  l <- matrix(0, nrow(data), 2)
#  t <- cbind(data,l)
#  dimnames(t) = list(c(1:nrow(data)) ,c('image', 'rsle', 'scatter'))
#  write.table(t, file= paste("D:/sfugger/Data/first_run_tables/tile",n,".txt", sep=""))
#}

#local projection (e.g.lambert conformal conic), tiles and MODIS must already have local projection!
lcccrs <- CRS("+proj=lcc +lat_1=49 +lat_2=46 +lat_0=47.5 +lon_0=13.33333333333333 +x_0=400000 +y_0=400000 +ellps=GRS80 +units=m +no_defs")

#allocate output values
snow <- 200
cloud <- 50
land <- 25

#for noData images
#logger <- "fails"

#for plotting results
#breakpoints <- c(20,30,60,1000,2000,3000,4000)
#colors <- c("green","darkgrey","skyblue3","skyblue2","skyblue1","skyblue" )


#this is a loop for all MODIS images listed in table images.txt
for (inp in 550:nrow(data)){
 
  MODIS <- paste("D:/sfugger/Data/combined_images/", data[inp,1], sep="")
  if (!file.exists(MODIS)){
    next
  }
  
  tic()
  
  r1 <- raster(MODIS)
  proj4string(r1) <- lcccrs
  
  #and loop for all tiles
  
  for (ti in 2:length(tileslist)) {
    #import dem-region
    tile<-raster(tileslist[ti])
    proj4string(tile) <- lcccrs
    
    
    #number of pixels classified as clouds, land, snow within tile-region
    r1crop <- crop(r1,tile)
    nc<-freq(r1crop,value=cloud)
    ns<-freq(r1crop,value=snow)
    nl<-freq(r1crop,value=land)
    #number of all pixels within a tile
    nn<-freq(reclassify(r1crop, c(1,256,1)),value=1)
    
    #load table for tile
    tiletab <- read.table(paste("D:/sfugger/Data/first_run_tables/tile",ti,".txt",sep=""))
    
    #proceed only if cloud cover does not exceed threshold  
    cldcov <- nc/nn
    if (cldcov >= 0.7){
      tiletab[inp,2] <- cloud
      tiletab[inp,3] <- NA
      write.table(tiletab, file= paste("D:/sfugger/Data/first_run_tables/tile",ti,".txt", sep=""))
      next
      
    } #end for if cloud cover
    
    
    #proceed only if there is enough snow pixels in the tile, declare tiles as land if not
    
    if (ns < 0.005*nn) {
      tiletab[inp,2] <- land
      tiletab[inp,3] <- NA
      write.table(tiletab, file= paste("D:/sfugger/Data/first_run_tables/tile",ti,".txt", sep=""))
      next
    } #end of if no snow
    
    #extract minim,maximum from dem for given basin
    demmin<-minValue(tile)
    demmax<-maxValue(tile)
    
    #loop from min to max elevation, steps of 10m, finding RSLE
    rsle<--999
    rsl<-10000000000
    
#################################################################################################
#this burns the most time - not anymore!!
    
    
    mtile <- as.matrix(tile)
    mr1crop <- as.matrix(r1crop)
    
    for (elev in seq(demmin, demmax, by=50)){
      tmp <- mtile
      tmp[tmp > elev] <-NA
      tmp[!is.na(tmp)] <- 1
      tmp <- tmp*mr1crop 
      
      nss<-length(which(tmp == snow)) #frequency of snow pixels below snow line
      nll<-nl-length(which(tmp == land)) #frequency of land pixels above snow line
      #minimize sum of the two
      
      if(nll+nss <= rsl) {
        rsl<-nll+nss
        rsle<-elev
        
      }#end if snowline
    }#end for elev 
    
  
#####################################################################################################    
    
    #write table with rsle and rsl
    tiletab[inp,2] <- rsle
    tiletab[inp,3] <- rsl
    write.table(tiletab, file= paste("D:/sfugger/Data/first_run_tables/tile",ti,".txt", sep=""))
  }#end tiles loop
toc()
} #end of loop for all MODIS images

#remove bad images (insert after loading MODIS raster file)
#if (sum(is.na(getValues(r1))) > 0.3*ncell(r1)){
#logger <- cbind(logger, substring(MODIS, first = 33, last = 39))
#write.table(logger, file= "D:/sfugger/Data/first_run_tables/logger.txt")
#next
#}
