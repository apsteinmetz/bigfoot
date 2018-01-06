library(tidyverse)
library(broom)
library(lubridate)
library(ggplot2)
library(rgdal)
library(choroplethr)
library(magick)


bfro_data<-read_csv("bfro-report-locations.csv")
bfro_data<-bfro_data %>% mutate(region=as.character(NA)) %>% 
  select(matches("[^(title)]"),title)


#Since we only have lat/lon, not state info, we have to figure out what state each coordinate is in.  First we get an ESRI Shapefile that has a polygon vector for each state.

# files from https://www.census.gov/geo/maps-data/data/cbf/cbf_counties.html put in gis directory
states_map_50<-readOGR(dsn="gis",layer="cb_2016_us_state_20m")

#The  `tidy`/`nest` functions let us extract the polygon data in a way we can use. First we extract the polygons, then assign a state name as `region` to each polygon vector.  Finally, we unnest the table so that each vertex has a state label assigned to it.
  
states_map_50_nested<-tidy(states_map_50) %>% 
  as_data_frame() %>% 
  mutate(id=as.factor(id)) %>% 
  group_by(id) %>% 
  nest() %>% 
  bind_cols(region=states_map_50$NAME) %>% 
  group_by(region)
  
states_map<-states_map_50_nested %>% unnest()  %>% select(id,region,long,lat)
states_map
#This table is a format that `point.in.poly` can use.

#Use the point.in.poly function to assign a state to the lat/long data in data set from we got from Kaggle.  We loop through each state and test all sighting coordinates against current the state polygon.  We flag each 'hit' as `TRUE` and assign the current state label to each hit in `bfro_data`.
for (st in states_map_50_nested$region){
  poly.x<-states_map_50_nested %>% filter(region==st) %>% .$data %>% .[[1]] %>% .$long
  poly.y<-states_map_50_nested %>% filter(region==st) %>% .$data %>% .[[1]] %>% .$lat
  state_flag<-as.logical(point.in.polygon(bfro_data$longitude,bfro_data$latitude,poly.x,poly.y))
  if (TRUE %in% state_flag){
    bfro_data[as.logical(state_flag),]$region=st
  }
  
}
#Finally, to clean up the data set we get the year from the time stamp, make sure no impossible dates exist and summarise the sighting counts by state, then by state and year.
bfro_data<-bfro_data %>% 
  mutate(Year=year(timestamp)) %>% 
  filter(Year<=year(Sys.Date())) %>%
  select(Year,region,everything()) %>% 
  arrange(Year,region,number)
state_sum<-bfro_data %>%  mutate(region=str_to_lower(region)) %>% group_by(region) %>% summarise(value=n())
state_year_sum<-bfro_data  %>% mutate(region=str_to_lower(region)) %>% group_by(region,Year) %>% summarise(value=n())
#fill in missing years with zero
state_year_sum<-state_year_sum %>%  
  complete(Year=full_seq(state_year_sum$Year,1),fill=list(value=0))

maxYear<-max(state_year_sum$Year)
maxSights<-max(state_year_sum$value)
startYear=1960




