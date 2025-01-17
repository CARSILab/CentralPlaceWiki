library(spatstat)
library(rgdal)
library(maptools)
library(RColorBrewer)
library(raster)

setwd("~/Dropbox/Code/CentralPlaceWiki/R_Analysis")

# load data
declared  <- readOGR("Shapefiles","Declared_proj")
extracted <- readOGR("Shapefiles","Extracted_proj")

#germany <- readShapePoly('de_states.shp', proj4string=CRS("+proj=utm +zone=32 +ellps=GRS80 +units=m +no_defs"))

germany <- readOGR("Shapefiles", "de-states")

#change germany polygon to owin type, so that we can use it as the boundary for our point pattern analysis
germany.window <- as.owin(germany)
class(germany.window)

# change the point layers to spatstat point patterns and set the window to the border of germany
declared.ppp  <- as.ppp(coordinates(declared),  germany.window)
extracted.ppp <- as.ppp(coordinates(extracted), germany.window)

# class(declared.ppp)
# class(extracted.ppp)

# summary(declared.ppp)
# summary(extracted.ppp)

# plot.ppp(declared.ppp)
# plot.ppp(extracted.ppp)


# these take quite long to run, 

# k_ex <- Kest(extracted.ppp)
# k_ex
# k_dec <- Kest(declared.ppp)
# k_dec

# plot(k_ex)
# plot(k_dec)

# plot(envelope(extracted.ppp,Kest))
# plot(envelope(declared.ppp,Kest))

#duplicated(declared.ppp,extracted.ppp)

# compute nearest neighbors between the two point patterns
nn <- nncross(declared.ppp,extracted.ppp)

neighbors = nn$which # indicies of nearest neighbors
distances = nn$dist  # distances


plot(superimpose(declared.ppp=declared.ppp,extracted.ppp=extracted.ppp), main="nncross", cols=c("red","blue"))
arrows(declared.ppp$x, declared.ppp$y, extracted.ppp[neighbors]$x, extracted.ppp[neighbors]$y, length=0.15)

boxplot(distances/1000)
summary(distances/1000)
sd(distances/1000)

hist(distances/1000)




# make subsets of both patterns that contain ONLY the points
# that don't have a corresponding point at the same location
i = distances > 0
declared_unique = declared[i,]
declared_unique.ppp  <- as.ppp(coordinates(declared_unique),  germany.window)

nonneighbors = neighbors[i]
extracted_unique = extracted[nonneighbors,]
extracted_unique.ppp <-as.ppp(coordinates(extracted_unique), germany.window)

plot(superimpose(declared_unique.ppp=declared_unique.ppp,extracted_unique.ppp=extracted_unique.ppp), main="uniques", cols=c("red","blue"))

# also takes quite long again...
# k_ex_u <- Kest(extracted_unique.ppp)
# k_ex_u
# k_dec_u <- Kest(declared_unique.ppp)
# k_dec_u

# plot(k_ex_u)
# plot(k_dec_u)

plot(germany)

extracted.desity <- density.ppp(extracted.ppp, eps=20000, 0.2)
declared.density <- density.ppp(declared.ppp, eps=20000, 0.2)

l <- max(max(extracted.desity$v, na.rm = TRUE), max(extracted.desity$v, na.rm = TRUE))


plot(extracted.desity, zlim=c(0,l))
plot(declared.density, zlim=c(0,l))

# calc and plot difference:
diff.density <- declared.density - extracted.desity

absmin = abs(min(diff.density$v, na.rm = TRUE))
absmax = max(diff.density$v, na.rm = TRUE)

limit = max(absmin, absmax)
limit

plot(diff.density, zlim=c(-1*limit,limit), col=brewer.pal(11,"RdBu"))


cor.test(c(c(extracted.desity)$v), c(c(declared.density)$v))

# load population density data
popdens <- raster("Shapefiles/GeoBasisDE/Gemeinden-25km-raster.tif")

popdens
plot(popdens)

# this turns the two matrices into 1D-vectors and conducts a test for Pearson's product-moment correlation: 
cor.test(c(c(extracted.desity)$v), c(as.matrix(popdens)), na.rm=TRUE)
cor.test(c(c(declared.density)$v), c(as.matrix(popdens)), na.rm=TRUE)
plot(c(c(extracted.desity)$v), c(as.matrix(popdens)))


# Let's save the diff.density to a raster to make a prettier map later:
diffraster <- raster(diff.density)
# copy over the crs from the popdens raster:
crs(diffraster) <- popdens@crs
# save as geotiff:
writeRaster(diffraster, 'IntensityDifference.tif')
