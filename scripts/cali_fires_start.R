# load libraries for data and mapping
library(tidyverse)
library(sf)
library(httr)
library(lubridate)
library(geojsonio)
library(stringr)

# source feeds from calfire


# Define the URL and the destination file path
url <- "https://services1.arcgis.com/jUJYIo9tSA7EHvfZ/arcgis/rest/services/CA_Perimeters_NIFC_FIRIS_public_view/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
#destfile <- "data/CA_Perimeters_NIFC_FIRIS_public_view.geojson"

# Download the file using httr
#response <- GET(url)
#writeBin(content(response, "raw"), destfile)

# Load the downloaded geojson file
cali_fires <- st_read(url) %>% janitor::clean_names()

# Make geometries valid
cali_fires <- st_make_valid(cali_fires)

# Convert ArcGIS date format to real date
cali_fires <- cali_fires %>%
  mutate(poly_date_current = as.POSIXct(poly_date_current / 1000, origin = "1970-01-01"))

# Filter dataset to only those updated in the last 14 days
#cali_fires <- cali_fires %>%
  #filter(poly_date_current >= Sys.Date() - 15)

# Removing the code letters etc from mission names to create a standard common fire name
cali_fires <- cali_fires %>%
  mutate(fire_name = str_replace(mission, "CA-[A-Z]{3}-", "")) %>%
  mutate(fire_name = str_replace(fire_name, "-[A-Za-z0-9]{4}$", "")) %>%
  mutate(fire_name = str_to_upper(fire_name)) %>%
  mutate(fire_name = paste0(fire_name, " FIRE"))

# Manually rename 2025-CALFD-000738 FIRE as PARADISE FIRE
cali_fires <- cali_fires %>%
  mutate(fire_name = str_replace(fire_name, "2025-CALFD-000738 FIRE", "PALISADES FIRE"))
  
# Output and save a file with the history/past perimeters for these specific fires
cali_fires_history_perimeters <- cali_fires
# export geojson file to data directory
geojson_write(cali_fires_history_perimeters, file = "data/history_cali_fire_perimeters.geojson")

# Group by mission and summarize acres burned
#cali_fires <- cali_fires %>%
#  group_by(fire_name) %>%
#  summarise(acres_burned = max(area_acres), .groups = "drop")

# Choose the fire_name record with the latest date in poly_date_current
cali_fires <- cali_fires %>%
  group_by(fire_name) %>%
  slice_max(order_by = poly_date_current, n = 1) %>%
  mutate(acres_burned = round(area_acres)) %>%
  select(fire_name, acres_burned, poly_date_current, geometry, display_status)

# Round acres to nearest acres
#cali_fires <- cali_fires %>%
#  mutate(acres_burned = round(acres_burned))

# add a field called timestamp that is the current system time but in the Pacific time zone
cali_fires <- cali_fires %>%
  mutate(timestamp = as.POSIXct(Sys.time(), tz = "America/Los_Angeles"))

# remove latest_cali_fires.geojson in data directory
file.remove("data/latest_cali_fires.geojson")

# export geojson file to data directory
geojson_write(cali_fires, file = "data/latest_cali_fires.geojson")

# EVAC geojson from state of california

evac_url <- "https://services3.arcgis.com/uknczv4rpevve42E/arcgis/rest/services/CA_EVACUATIONS_PROD/FeatureServer/0/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnTrueCurves=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token="
evac_destfile <- "data/CA_evacuations.geojson"

download.file(evac_url, evac_destfile, mode = "wb")

# Download the file using httr
#response <- GET(evac_url)
#writeBin(content(response, "raw"), evac_destfile)

#get updated datetime (sys.time)
current_time = Sys.time()

current_time_posix <- as.POSIXct(current_time)

updated_datetime <- format(as.POSIXct(current_time), format = "%Y-%m-%d %H:%M:%S", tz = "America/Los_Angeles")

# Load the downloaded geojson file
cali_evac <- st_read(evac_destfile) %>% janitor::clean_names()
# Make geometries valid
cali_evac <- st_make_valid(cali_evac) %>% 
  mutate(timestamp = updated_datetime)

# create a quick leaflet map showing the perimters from cali_fires on a map with a satellite view provider layer
#quick_evacmap <- leaflet(cali_evac) %>%
# addProviderTiles(providers$Esri.WorldImagery) %>%
# addPolygons(color = "red", weight = 2, opacity = 1, fillOpacity = 0.2) %>%
# addLegend("bottomright", colors = "red", labels = "Latest Evacs")
# add a popup that includes the fire name, acres burned, containment percentage and update date

# remove latest_cali_fires.geojson in data directory
file.remove("data/latest_cali_evac.geojson")

# export geojson file to data directory
geojson_write(cali_evac, file = "data/latest_cali_evac.geojson")


