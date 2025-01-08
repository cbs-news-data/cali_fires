# load libraries for data and mapping
library(tidyverse)
library(sf)
library(leaflet)
library(leaflet.extras)
library(geojsonio)
library(leaflet.providers)

# source feeds from calfire

# evacs: https://www.arcgis.com/home/item.html?id=9be87abf402b40f6bb703f6d7a2b39c5 and
# https://www.arcgis.com/home/item.html?id=9be87abf402b40f6bb703f6d7a2b39c5&view=service#overview
# california perimeters: 
# option: https://gis.data.ca.gov/datasets/CALFIRE-Forestry::california-fire-perimeters-all/explore

# Import geojson file in data folder
cali_fires <- st_read("data/CA_Perimeters_NIFC_FIRIS_public_view.geojson") %>% janitor::clean_names()

# Make geometries valid
cali_fires <- st_make_valid(cali_fires)

# Filter dataset to only those updated in the last 14 days
cali_fires <- cali_fires %>%
  filter(poly_date_current >= Sys.Date() - 3)

# Group by mission and summarize acres burned
cali_fires <- cali_fires %>%
  group_by(mission) %>%
  summarise(acres_burned = sum(area_acres), .groups = "drop")



# create a quick leaflet map showing the perimters from cali_fires on a map with a satellite view provider layer
quick_firemap <- leaflet(cali_fires) %>%
  addProviderTiles(providers$Esri.WorldImagery) %>%
  addPolygons(color = "red", weight = 2, opacity = 1, fillOpacity = 0.2) %>%
  addLegend("bottomright", colors = "red", labels = "Latest Fire Perimeters") 
# add a popup that includes the fire name, acres burned, containment percentage and update date

# remove latest_cali_fires.geojson in data directory
file.remove("data/latest_cali_fires.geojson")
# export geojson file to data directory
geojson_write(cali_fires, file = "data/latest_cali_fires.geojson")



