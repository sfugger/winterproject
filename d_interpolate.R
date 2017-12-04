#interpolation of rsle and land values and creation output images

library(zoo)
library(raster)
library(gtools)
library(SpaDES)
library(tictoc)

tablist <- mixedsort(sort(list.files("D:/sfugger/Data/speedup_tables", pattern = ".txt", full.names = TRUE)))
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
  write.table(int, file= paste("D:/sfugger/Data/speedup_tables_out/tile",i,".txt", sep=""))
}

#assign values to raster

tileslist <- mixedsort(sort(list.files("D:/sfugger/Data/first_run_tiles", pattern = ".tif", full.names = TRUE)))
tablist <-mixedsort(sort(list.files("D:/sfugger/Data/first_run_tables_out", pattern = ".txt", full.names = TRUE)))

bucket <- raster("D:/sfugger/Data/merge.tif")
bucket[!is.na(bucket)] <- 0
days <- nrow(read.table(tablist[1]))

for (d in 2477:days) {
  tic()  
  outras <- bucket
    
    for(t in 1:length(tileslist)){
      list <- read.table(tablist[t])
      tile <- raster(tileslist[t]) 
      outras[(coords=extent(tile))] <- list$rsle[d]
    }
  writeRaster(outras, filename=paste("D:/sfugger/Data/first_run_output/", substring(list$image[d], first = 1, last = 4), "/", substring(list$image[d], first = 1, last = 7), sep=""), format="GTiff", overwrite=TRUE)
  toc() 
}


  
