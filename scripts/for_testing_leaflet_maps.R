# load libraries for data and mapping
library(tidyverse)
library(sf)
library(leaflet)
library(leaflet.extras)
library(leaflet.providers)
library(httr)
library(lubridate)
library(geojsonio)

# source feeds from calfire

# Define the URL and the destination file path
test_url <- "https://services1.arcgis.com/jUJYIo9tSA7EHvfZ/arcgis/rest/services/CA_Perimeters_NIFC_FIRIS_public_view/FeatureServer/0/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=OBJECTID+DESC&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=50&returnZ=false&returnM=false&returnTrueCurves=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token="
test_destfile <- "data/TEST_CA_Perimeters_NIFC_FIRIS_public_view.geojson"

# Download the file using httr
test_response <- GET(url)
writeBin(content(test_response, "raw"), test_destfile)

# Load the downloaded geojson file
test_cali_fires <- st_read("https://services1.arcgis.com/jUJYIo9tSA7EHvfZ/arcgis/rest/services/CA_Perimeters_NIFC_FIRIS_public_view/FeatureServer/0/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=OBJECTID+DESC&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=50&returnZ=false&returnM=false&returnTrueCurves=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token=") %>% janitor::clean_names()

# Import geojson file in data folder
# cali_fires <- st_read("data/CA_Perimeters_NIFC_FIRIS_public_view.geojson") %>% janitor::clean_names()

# Make geometries valid
test_cali_fires <- st_make_valid(cali_fires)

# Convert ArcGIS date format to real date
cali_fires <- cali_fires %>%
  mutate(poly_date_current = as.POSIXct(poly_date_current / 1000, origin = "1970-01-01"))


# Repeat for fire_discovery_date and edit_date
#cali_fires <- cali_fires %>%
#  mutate(fire_discovery_date = as.POSIXct(fire_discovery_date / 1000, origin = "1970-01-01"),
#         edit_date = as.POSIXct(edit_date / 1000, origin = "1970-01-01"))

# Filter dataset to only those updated in the last 14 days
cali_fires <- cali_fires %>%
  filter(poly_date_current >= Sys.Date() - 3)

# Group by mission and summarize acres burned
cali_fires <- cali_fires %>%
  group_by(mission) %>%
  summarise(acres_burned = max(area_acres), .groups = "drop")
# Round acres to nearest acres
cali_fires <- cali_fires %>%
  mutate(acres_burned = round(acres_burned))

# add a field called timestamp that is the current system time but in the Pacific time zone
cali_fires <- cali_fires %>%
  mutate(timestamp = as.POSIXct(Sys.time(), tz = "America/Los_Angeles"))

# filter cal_fires2 to include objectid 1267
cali_fires2 <- cali_fires2 %>%
  filter(objectid == 1267)


# create a quick leaflet map showing the perimters from cali_fires on a map with a satellite view provider layer
quick_firemap <- leaflet(cali_fires2) %>%
  addProviderTiles(providers$Esri.WorldImagery) %>%
  addPolygons(color = "red", weight = 2, opacity = 1, fillOpacity = 0.2) %>%
  addPolygons(data = cali_fires, color = "blue", weight = 2, opacity = 1, fillOpacity = 0.2) %>%
  addLegend("bottomright", colors = "red", labels = "Latest Fire Perimeters") 
# add a popup that includes the fire name, acres burned, containment percentage and update date


# archive the latest_cali_fires.geojson file in the data directory renamed with a time and date
file.rename("data/latest_cali_fires.geojson", paste0("data/archive_cali_fires_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".geojson"))

# remove latest_cali_fires.geojson in data directory
# file.remove("data/latest_cali_fires.geojson")

# export geojson file to data directory
geojson_write(cali_fires, file = "data/latest_cali_fires.geojson")


# evacs: https://www.arcgis.com/home/item.html?id=9be87abf402b40f6bb703f6d7a2b39c5 and
# https://www.arcgis.com/home/item.html?id=9be87abf402b40f6bb703f6d7a2b39c5&view=service#overview

evac_url <- "https://services3.arcgis.com/uknczv4rpevve42E/arcgis/rest/services/CA_EVACUATIONS_PROD/FeatureServer/0/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnTrueCurves=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token="
evac_destfile <- "data/CA_evacuations.geojson"
# Download the file using httr
response <- GET(evac_url)
writeBin(content(response, "raw"), evac_destfile)


# Load the downloaded geojson file
cali_evac <- st_read(evac_destfile) %>% janitor::clean_names()
# Make geometries valid
cali_evac <- st_make_valid(cali_evac)

# create a quick leaflet map showing the perimters from cali_fires on a map with a satellite view provider layer
quick_evacmap <- leaflet(cali_evac) %>%
  addProviderTiles(providers$Esri.WorldImagery) %>%
  addPolygons(color = "red", weight = 2, opacity = 1, fillOpacity = 0.2) %>%
  addLegend("bottomright", colors = "red", labels = "Latest Evacs")
# add a popup that includes the fire name, acres burned, containment percentage and update date

quick_evacmap

# remove latest_cali_fires.geojson in data directory
file.remove("data/latest_cali_evac.geojson")

# export geojson file to data directory
geojson_write(cali_evac, file = "data/latest_cali_evac.geojson")







