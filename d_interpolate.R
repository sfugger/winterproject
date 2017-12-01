#interpolation of rsle and land values and creation output images

library(zoo)
library(raster)
library(gtools)
library(SpaDES)
library(tictoc)

tablist <- mixedsort(sort(list.files("D:/sfugger/Data/first_run_tables", pattern = ".txt", full.names = TRUE)))
#head(tablist)

#supercomplicated interpolation (list with different kind of values: clouds, land, rsle)
for (i in 1:length(tablist)) {
  #read rsle column
  int <- read.table(tablist[i])
  #1. fill cloud gaps between rsle values
  int1 <- int$rsle
  int1[int1 == 50 | int1 == 0 | int1 == 25] <- NA
  int1 <- na.approx(int1, maxgap = 8, na.rm = FALSE)
  #2. fill cloud gaps between land values
  int2 <- int$rsle
  int2[int2 > 25 | int2 == 0] <- NA
  int2 <- na.approx(int2, maxgap = 8, na.rm = FALSE)
  #3. merge interpolated lists
  idx <- which(int$rsle == 25)
  int1[idx] <- 25
  idx <- which(is.na(int1))
  int1[idx] <- int2[idx]
  int$rsle <- replace(int1, is.na(int1), 50)
  write.table(int, file= paste("D:/sfugger/Data/first_run_tables_out/tile",i,".txt", sep=""))
}

#write rsle into tiles
#read tileslist
tileslist <- mixedsort(sort(list.files("D:/sfugger/Data/first_run_tiles", pattern = ".tif", full.names = TRUE)))
tablist <-mixedsort(sort(list.files("D:/sfugger/Data/first_run_tables_out", pattern = ".txt", full.names = TRUE)))
#to get number of days
days <- nrow(read.table(tablist[1]))


for(d in 144:days) {
tic()
    for(t in 1:length(tileslist)) {
    tile <- raster(tileslist[t])
    list <- read.table(tablist[t])
    tile[] <- list$rsle[d]
    writeRaster(tile, filename=paste("D:/sfugger/Data/first_run_tiles_out/","tileout",t, sep=""), format="GTiff", overwrite=TRUE)  
  }
  tilesoutlist <- list.files("D:/sfugger/Data/first_run_tiles_out/", pattern = ".tif", full.names = TRUE)
  tilesout <- lapply(tilesoutlist, raster) 
  newras <- mergeRaster(tilesout)
  writeRaster(newras, filename=paste("D:/sfugger/Data/first_run_output/", substring(list$image[d], first = 1, last = 4), "/", substring(list$image[d], first = 1, last = 7), sep=""), format="GTiff", overwrite=TRUE)    
toc()
}
  


         