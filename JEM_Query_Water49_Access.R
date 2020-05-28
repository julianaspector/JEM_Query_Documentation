library(arcgisbinding)
library(sf)
library(tools)
library(utils)
library(tidyverse)
library(janitor)
library(rstudioapi)
library(svDialogs)
library(data.table)
library(DBI)

# SETUP ----
# the following line is for getting the path of your current open file
current_path <- getActiveDocumentContext()$path
# The next line set the working directory to the relevant one:
setwd(dirname(current_path))

# set up Google Chrome as default browser and select download file location in settings

# run this line before using arcgisbinding pkg, should receive a successful connection to ArcGIS server message in console
arc.check_product()

# pause function
readKey <- function() {
  line <- readline(prompt = "Press [enter] to continue")
}

# open HUC layers from Water49 ----
# will need to set path for individual user

hu_10 <-
  arc.open(
    "C:/Users/USERNAME/AppData/Roaming/ESRI/Desktop10.6/ArcCatalog/Connection to water49db.sde/WBGIS.WatershedBoundaryDatasetApr2016/WBGIS.WBDHU10_041216"
  )
hu_12 <-
  arc.open(
    "C:/Users/USERNAME/AppData/Roaming/ESRI/Desktop10.6/ArcCatalog/Connection to water49db.sde/WBGIS.WatershedBoundaryDatasetApr2016/WBGIS.WBDHU12_041216"
  )
hu_8 <-
  arc.open(
    "C:/Users/USERNAME/AppData/Roaming/ESRI/Desktop10.6/ArcCatalog/Connection to water49db.sde/WBGIS.WatershedBoundaryDatasetApr2016/WBGIS.WBDHU8_041216"
  )

# Choose watershed ----

# enter HUC chosen
huc <-
  dlgInput("Enter 'hu_10', 'hu_12', or 'hu_8.'", Sys.info()["huc"])$res

# enter OBJECTID for watershed of interest based on HUC chosen
objid <- dlgInput("Enter Object ID.", Sys.info()["objid"])$res

#If you need to select multiple watershed areas, can enter a second OBJECTID
#objid_2 <- dlgInput("Enter Object ID.", Sys.info()["objid_2"])$res

# Selecting watershed with SQL query
watershed <-
  arc.select(object = get(huc),
             where_clause = paste0("OBJECTID =", objid, ""))

# Example of SQL query with multiple watersheds selected
#watershed <- arc.select(object=get(huc), where_clause= paste0("OBJECTID =",objid_1," OR OBJECTID=",objid_2,""))

# Pulling relevant documents from eWRIMS ----

# If SQL query returns record(s), will pull all relevant documents from eWRIMS based on points of diversion in watershed
# If SQL query is not constructed correctly, will return error in console

correctSQL <- function(x) {
  # open PODs from Water49, will need to amend file path for individual user
  POD <-
    arc.open(
      "C:/Users/USERNAME/AppData/Roaming/ESRI/Desktop10.6/ArcCatalog/Connection to water49db.sde/WBGIS.POINTS_OF_DIVERSION"
    )
  
  # make PODs accessible
  POD <- arc.select(object = POD)
  
  # convert to sf objects
  POD <- arc.data2sf(POD)
  watershed <- arc.data2sf(watershed)
  
  # make sure POD and watershed are in same coordinate system
  POD <- st_transform(POD, crs = 4326)
  watershed <- st_transform(watershed, crs = 4326)
  
  # find PODs within watershed
  # '<<-' will write variable to global environment within function
  POD_in_watershed <<- st_intersection(POD, watershed)
  
  # now get list of all application IDs in eWRIMS from reading eWRIMS flat file
  flatFULL <-
    fread(
      "www/ewrims_flat_file.csv",
      header = TRUE,
      stringsAsFactors = FALSE,
      data.table = FALSE,
      blank.lines.skip = TRUE
    )
  flat <- flatFULL
  
  app_numbers <- sort(unique(POD_in_watershed$APPL_ID))
  app_numbers <- as.character(app_numbers)
  
  flat <- data.frame(flat[, c(2)])
  colnames(flat) <- c("APPL_ID")
  
  # determine APPL_IDs for state filings
  SF <- filter(flat, grepl('SF', APPL_ID))
  
  # if first 7 characters of APPL_ID match, add SF to ending
  add_SF <- intersect(app_numbers, substr(SF$APPL_ID, 1, 7))
  add_SF_recode <- paste0(add_SF, "SF")
  app_numbers_recoded <-
    data.frame(add_SF_recode[match(app_numbers, add_SF)])
  
  # add re-coded application IDs to application ID list
  
  df <- cbind(app_numbers_recoded, app_numbers)
  df <- df %>% mutate_all(as.character)
  colnames(df) <- c("recoded", "original")
  df$recoded[is.na(df$recoded)] <- df$original[is.na(df$recoded)]
  
  app_numbers <- df$recoded
  
  # remove R from end of domestic statements, otherwise cannot link with flat file
  
  app_numbers <<- sub("R$", "", app_numbers)
  
  # create list of links to navigate to for eWRIMS documents
  
  POD_in_watershed$link <- character(length(nrow(POD_in_watershed)))
  
  link <-
    function(x, y) {
      paste0(
        "https://ciwqs.waterboards.ca.gov/ciwqs/ewrims/DocumentRetriever.jsp?appNum=",
        x,
        "&wrType=",
        y
      )
    }
  
  S_links <-
    sapply(app_numbers[startsWith(app_numbers, "S")], link, "Statement%20of%20Div%20and%20Use")
  A_links <-
    sapply(app_numbers[startsWith(app_numbers, "A")], link, "Appropriative")
  SF_links <-
    sapply(app_numbers[endsWith(app_numbers, "SF")], link, "Appropriative (State Filing)")
  
  
  for (i in 1:length(A_links)) {
    browseURL(A_links[i])
  }
  
  for (i in 1:length(S_links)) {
    browseURL(S_links[i])
  }
  
  for (i in 1:length(SF_links)) {
    browseURL(SF_links[i])
  }
  
  # generate a count to see if all docs possible were downloaded from eWRIMS
  c <- sum(startsWith(app_numbers, "C"))
  d <- sum(startsWith(app_numbers, "D"))
  f <- sum(startsWith(app_numbers, "F"))
  l <- sum(startsWith(app_numbers, "L"))
  x <- sum(startsWith(app_numbers, "X"))
  
  # directory is where statements/applications were downloaded from eWRIMS
  a <-
    sum(startsWith(setdiff(
      app_numbers, file_path_sans_ext(list.files("ENTER DIRECTORY PATH HERE"))
    ), "A"))
  s <-
    sum(startsWith(setdiff(
      app_numbers, file_path_sans_ext(list.files("ENTER DIRECTORY PATH HERE"))
    ), "S"))
  
  
  total_WR <<- a + c + d + f + l + s + x
  
}

#call function
correctSQL(x)


# stop script here until you have identified eWRIMS documents with maps
readKey()

# Generate master list of all water rights in Bay-Delta boundary area ----
BayDelta_masterlist <-
  read.csv('www/Application_IDs_MasterList.csv')
BayDelta_masterlist <- BayDelta_masterlist %>% select("APPL_ID")
recode(BayDelta_masterlist$APPL_ID, "S17275" = "S017275") -> BayDelta_masterlist$APPL_ID
BayDelta_masterlist <- unique(BayDelta_masterlist)

# Calling in lists of maps that are available from legacy effort or eWRIMS ----

# directory will contain eWRIMS documents with PDF maps named by APPL_ID
# will need to look through all documents downloaded to determine which ones have maps
eWRIMS_available <-
  data.frame(file_path_sans_ext(list.files('ENTER DIRECTORY PATH HERE'))) 
eWRIMS_available <- eWRIMS_available %>% rename(APPL_ID = 1)
eWRIMS_available$Available_eWRIMS <- 'Y'

georeferenced_maps <-
  read.csv('www/Georeferenced_Legacy_Maps.csv')
georeferenced_maps <- georeferenced_maps %>% select("APPL_ID")
georeferenced_maps$Georeferenced <- 'Y'

license_maps <-
  read.csv('www/Scanned_Licensing_Maps.csv')
license_maps <- license_maps %>% rename(APPL_ID = 2)
license_maps <- license_maps %>% select(APPL_ID)
license_maps$License_Legacy <- 'Y'

legacy_maps <-
  read.csv('www/Scanned_Legacy_Maps.csv')
legacy_maps <-
  legacy_maps %>% rename(APPL_ID = ApplicationNumber) %>% select(APPL_ID)
legacy_maps <- unique(legacy_maps)
legacy_maps$Legacy_Scanned <- 'Y'

database_table <- left_join(BayDelta_masterlist, eWRIMS_available)
database_table <- left_join(database_table, georeferenced_maps)
database_table <- left_join(database_table, license_maps)
database_table <- left_join(database_table, legacy_maps)
database_table[is.na(database_table)] <- 'N'

# Create an ephemeral in-memory RSQLite database and generate query ----
con <- dbConnect(RSQLite::SQLite(), ":memory:")

dbWriteTable(con, "database_table", database_table)

res <- subset(database_table, APPL_ID %in% app_numbers)

# join APPL_IDs and availability information ----

POD_in_watershed <- inner_join(POD_in_watershed, res)
# remove unnecessary variables from environments
rm(
  BayDelta_masterlist,
  eWRIMS_available,
  georeferenced_maps,
  license_maps,
  legacy_maps
)

# Load Data from eWRIMS Flat Files ----
flatFULL <-
  fread(
    "www/ewrims_flat_file.csv",
    header = TRUE,
    stringsAsFactors = FALSE,
    data.table = FALSE,
    blank.lines.skip = TRUE
  )
flat <- flatFULL
flat <- flat[, c(2, 21, 26, 6, 7, 118)]
colnames(flat) <-
  c("APPL_ID",
    "PRIMARY_OWNER",
    "FACE_VALUE_AMOUNT_AF",
    "WR_TYPE",
    "STATUS",
    "COUNTY")

usesFULL <-
  fread(
    "www/ewrims_flat_file_use_season.csv",
    header = TRUE,
    stringsAsFactors = FALSE,
    data.table = FALSE,
    blank.lines.skip = TRUE
  )
uses <- usesFULL
uses <-
  uses[, c(77, 5)] #select only columns for APPL_ID and USE_CODE
colnames(uses) <- c("APPL_ID", "BEN_USE")
uses <-
  uses[order(uses$APPL_ID, uses$BEN_USE),] # sort both columns in ascending order
uses <-
  aggregate(BEN_USE ~ APPL_ID, data = uses, toString) # aggregate to have one row per APPL_ID with a list of uses

rip_pre1914 <-
  read.csv("www/20200213_Riparian and Pre1914 eWRIMS pull.csv") #Riparian and Pre-1914 water rights info
rip_pre1914$ACC_DATE <- NULL
rip_pre1914 <- rip_pre1914[order(rip_pre1914$APPL_ID),]
rip_pre1914 <- rip_pre1914[!duplicated(rip_pre1914$APPL_ID),]

table <- merge(flat, uses, all = TRUE)
table <-
  table[!(table$APPL_ID == ""),] #remove water rights with no APPL_ID
table <- merge(table, rip_pre1914, all = TRUE)
table <- table %>% replace_na(list(Riparian = "", Pre1914 = ""))

rm(flatFULL, flat, usesFULL, uses) #remove other eWRIMS data because they're all merged into table

#Table specific for Mokelumne River ----
MOK_table <-
  POD_in_watershed[, c(1, 2, 64:68)] #APPL_ID, POD_ID, map tracking columns
MOK_table$geometry <- NULL
MOK_table <- MOK_table[order(MOK_table$APPL_ID, MOK_table$POD_ID),]
MOK_table <-
  aggregate(
    POD_ID ~ APPL_ID + Georeferenced + License_Legacy + Legacy_Scanned + Available_eWRIMS,
    data = MOK_table,
    toString
  )
MOK_table <- merge(MOK_table, table, by = c("APPL_ID"))
MOK_table$Watershed <- "Mokelumne River"

write.csv(MOK_table, "MOK_River_Water_Rights_Table.csv")
maps_available <-
  MOK_table %>% filter(
    Georeferenced == 'Y' |
      License_Legacy == 'Y' |
      Legacy_Scanned == 'Y' | Available_eWRIMS == 'Y'
  )