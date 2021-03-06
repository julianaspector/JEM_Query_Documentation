library(sf)
library(tools)
library(utils)
library(janitor)
library(tidyverse)
library(rstudioapi)
library(data.table)
library(DBI)

# SET UP ----

# the following line is for getting the path of your current open file
current_path <- getActiveDocumentContext()$path
# The next line set the working directory to the relevant one:
setwd(dirname(current_path))

# define directories where: 1) eWRIMS documents will be downloaded and 2) maps identified will be saved
# remember to use "/" between folders in directory path
eWRIMS_download_location <- 'ENTER DIRECTORY PATH HERE'
id_maps_location <- 'ENTER DIRECTORY PATH HERE'

# Set up Google Chrome as default browser and select download file location in settings

# pause function
readKey <- function() {
  line <- readline(prompt = "Press [enter] to continue")
}

# Import local shapefiles ----
# The code in this section will need to be changed depending on watershed of interest.

legalDelta <- st_read('www/Legal_Delta.shp')
hu_8 <-  st_read('www/WBDHU8.shp')

# transform shapefiles used into same coordinate system
legalDelta <- st_transform(legalDelta, crs = 4326)
hu_8 <- st_transform(hu_8, crs = 4326)

MOK <- hu_8 %>% filter(Name == 'Upper Mokelumne')

watershed <- st_difference(MOK, legalDelta)


# If a correct SQL query was generated, script will return list of water rights in watershed ----
correctSQL <- function(x) {
  POD <- st_read("www/20200214_WBGIS_POD.shp")
  
  # make sure POD and watershed are in same coordinate system
  POD <- st_transform(POD, crs = 4326)
  watershed <- st_transform(watershed, crs = 4326)
  
  # find PODs within watershed
  # '<<-' will write variable to global environment within function
  POD_in_watershed <<- st_intersection(POD, watershed)
  
  # now get list of all application IDs in eWRIMS
  
  flatFULL <<-
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
  # determine SF APPL_IDs
  SF <- filter(flat, grepl('SF', APPL_ID))
  
  # if first 7 characters of APPL_ID match, add SF to ending
  add_SF <- intersect(app_numbers, substr(SF$APPL_ID, 1, 7))
  add_SF_recode <- paste0(add_SF, "SF")
  app_numbers_recoded <-
    data.frame(add_SF_recode[match(app_numbers, add_SF)])
  
  df <- cbind(app_numbers_recoded, app_numbers)
  df <- df %>% mutate_all(as.character)
  colnames(df) <- c("recoded", "original")
  df$recoded[is.na(df$recoded)] <- df$original[is.na(df$recoded)]
  
  app_numbers <- df$recoded
  
  # remove R from end of domestic statements, otherwise cannot link with flat file
  
  app_numbers <<- sub("R$", "", app_numbers)
  
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
  
  # you can comment out the next three loops if want to avoid downloading files from eWRIMS
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
  
  # directory is where eWRIMS documents were downloaded
  a <-
    sum(startsWith(setdiff(
      app_numbers, file_path_sans_ext(list.files(eWRIMS_download_location))
    ), "A"))
  s <-
    sum(startsWith(setdiff(
      app_numbers, file_path_sans_ext(list.files(eWRIMS_download_location))
    ), "S"))
  
  
  other_WR <<- a + c + d + f + l + s + x
  
}
correctSQL(x)

print(paste0("Number of water rights without documents: ", other_WR))
# directory path in next two lines is where eWRIMS documents were downloaded
print(paste0(
  "Number of documents downloaded from eWRIMS: ",
  length(list.files(eWRIMS_download_location))
))
print(paste0("Sum: ", sum(other_WR, length(
  list.files(eWRIMS_download_location)
))))
print(paste0("Number of unique application IDs: ", length(app_numbers)))
# Sum should be equivalent to number of unique application IDs, assuming all available documents from eWRIMS were downloaded

# stop script here until you have identified eWRIMS documents with maps, then press ENTER to continue
readKey()

# now get list of all application IDs in eWRIMS
flat <- flatFULL

flat <- data.frame(flat[, c(2)])
colnames(flat) <- c("APPL_ID")
# determine SF APPL_IDs
SF <- filter(flat, grepl('SF', APPL_ID))

# Generate master list of all water rights in Bay-Delta boundary area ----
BayDelta_masterlist <-
  read.csv('www/Application_IDs_MasterList.csv')
BayDelta_masterlist <- BayDelta_masterlist %>% select("APPL_ID")
recode(BayDelta_masterlist$APPL_ID, "S17275" = "S017275") -> BayDelta_masterlist$APPL_ID
BayDelta_masterlist <- unique(BayDelta_masterlist)
# if first 7 characters of APPL_ID match, add SF to ending
add_SF <-
  intersect(BayDelta_masterlist$APPL_ID, substr(SF$APPL_ID, 1, 7))
add_SF_recode <- paste0(add_SF, "SF")
app_numbers_recoded <-
  data.frame(add_SF_recode[match(BayDelta_masterlist$APPL_ID, add_SF)])

df <- cbind(app_numbers_recoded, BayDelta_masterlist$APPL_ID)
df <- df %>% mutate_all(as.character)
colnames(df) <- c("recoded", "original")
df$recoded[is.na(df$recoded)] <- df$original[is.na(df$recoded)]

BayDelta_masterlist$APPL_ID <- df$recoded

# remove R from end of domestic statements, otherwise cannot link with flat file

BayDelta_masterlist$APPL_ID <-
  sub("R$", "", BayDelta_masterlist$APPL_ID)

# Calling in lists of maps that are available from legacy effort or eWRIMS ----

# directory will contain eWRIMS documents with maps named by APPL_ID
# Note: If there are multiple maps with same APPL_ID, just add "_[number]" after APPL_ID (i.e. S017275_1, S017275_2, etc.)
# will need to look through all documents downloaded to determine which ones have maps
eWRIMS_available <-
  data.frame(file_path_sans_ext(list.files(id_maps_location)))
eWRIMS_available <- eWRIMS_available %>% rename(APPL_ID = 1)
eWRIMS_available$APPL_ID <-
  sub("_[0-9][0-9]", "", eWRIMS_available$APPL_ID)
eWRIMS_available$APPL_ID <-
  sub("_[0-9]", "", eWRIMS_available$APPL_ID)
eWRIMS_available <-
  data.frame(eWRIMS_available[!duplicated(eWRIMS_available), ])
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

dbDisconnect(con)

# join APPL_IDs and availability information ----

# if first 7 characters of APPL_ID match, add SF to ending
add_SF <-
  intersect(POD_in_watershed$APPL_ID, substr(SF$APPL_ID, 1, 7))
add_SF_recode <- paste0(add_SF, "SF")
app_numbers_recoded <-
  data.frame(add_SF_recode[match(POD_in_watershed$APPL_ID, add_SF)])

df <- cbind(app_numbers_recoded, POD_in_watershed$APPL_ID)
df <- df %>% mutate_all(as.character)
colnames(df) <- c("recoded", "original")
df$recoded[is.na(df$recoded)] <- df$original[is.na(df$recoded)]

POD_in_watershed$APPL_ID <- df$recoded

# remove R from end of domestic statements, otherwise cannot link with flat file

POD_in_watershed$APPL_ID <- sub("R$", "", POD_in_watershed$APPL_ID)


POD_in_watershed <- inner_join(POD_in_watershed, res)
# remove unnecessary variables from environments
rm(
  BayDelta_masterlist,
  eWRIMS_available,
  georeferenced_maps,
  license_maps,
  legacy_maps,
  df,
  con,
  hu_8,
  legalDelta,
  MOK,
  res,
  SF,
  add_SF,
  add_SF_recode,
  other_WR,
  app_numbers_recoded,
  database_table
)

# Load Data from eWRIMS Flat Files ----

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
  uses[order(uses$APPL_ID, uses$BEN_USE), ] # sort both columns in ascending order
uses <-
  aggregate(BEN_USE ~ APPL_ID, data = uses, toString) # aggregate to have one row per APPL_ID with a list of uses

rip_pre1914 <-
  read.csv("www/20200213_Riparian and Pre1914 eWRIMS pull.csv") #Riparian and Pre-1914 water rights info
rip_pre1914$ACC_DATE <- NULL
rip_pre1914 <- rip_pre1914[order(rip_pre1914$APPL_ID), ]
rip_pre1914 <- rip_pre1914[!duplicated(rip_pre1914$APPL_ID), ]

table <- merge(flat, uses, all = TRUE)
table <-
  table[!(table$APPL_ID == ""), ] #remove water rights with no APPL_ID
table <- merge(table, rip_pre1914, all = TRUE)
table <- table %>% replace_na(list(Riparian = "", Pre1914 = ""))

rm(flatFULL, flat, usesFULL, uses) #remove other eWRIMS data because they're all merged into table

#Table specific for Mokelumne River ----
MOK_table <-
  POD_in_watershed[, c(1, 2, 64:68)] #APPL_ID, POD_ID, map tracking columns
MOK_table$geometry <- NULL
MOK_table <- MOK_table[order(MOK_table$APPL_ID, MOK_table$POD_ID), ]
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