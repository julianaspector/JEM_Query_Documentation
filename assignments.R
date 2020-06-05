library(sf) # for reading gdb attribute table
library(dplyr)
library(openxlsx) 
library(DataCombine) # FillIn function

# Read in new geodatabase attribute table ----
gdb <- st_read("ENTER PATH HERE")
gdb <- st_sf(gdb)

# remove geometry columns
st_geometry(gdb) <- NULL
# rename columns that match the tracking spreadsheet so FillIn function will work 
gdb <- gdb %>% rename(APPL_ID=Ap_ID, 
                      Data_Conf_gdb = Data_Conf,
                      Conf_Notes_gdb = Conf_Notes,
                      Calc_Acr_gdb = Calc_Acr)

# Assign APPL_IDs to staff ----
gdb$Reviewer.one <- c(rep('Stanley', 29), rep('Juliana', 30), rep('Rob', 29))
gdb$Reviewer.two <- c(rep('Rob', 29), rep('Stanley', 30), rep('Juliana', 29))
gdb$Deliverable_status <- 'Yes'

# only select necessary columns from geodatabase attribute table
gdb <- gdb %>% select(APPL_ID, 
                      Reviewer.one, 
                      Reviewer.two, 
                      Deliverable_status, 
                      Data_Conf_gdb,
                      Conf_Notes_gdb,
                      Calc_Acr_gdb)

# Read in latest version of tracking spreadsheet after downloading ----
tracking <- read.xlsx('ENTER PATH HERE')
# Make replaced variables same types as target variables ----
tracking$Reviewer.1 <- as.character(tracking$Reviewer.1)
tracking$Reviewer.2 <- as.character(tracking$Reviewer.2)
tracking$Calc_Acr <- as.integer(tracking$Calc_Acr)
tracking$Data_Conf <- as.factor(tracking$Data_Conf)
tracking$Conf_Notes <- as.factor(tracking$Conf_Notes)

# Apply FillIn function ----
# Do not have any cells with NA as character

complete <- FillIn(D1 = tracking, 
                   D2 = gdb,
                   Var1 = "Reviewer.1",
                   Var2 = "Reviewer.one",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")

complete <- FillIn(D1 = complete, 
                   D2 = gdb,
                   Var1 = "Reviewer.2",
                   Var2 = "Reviewer.two",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")

complete <- FillIn(D1 = complete, 
                   D2 = gdb,
                   Var1 = "Deliverable",
                   Var2 = "Deliverable_status",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")

complete <- FillIn(D1 = complete, 
                   D2 = gdb,
                   Var1 = "Data_Conf",
                   Var2 = "Data_Conf_gdb",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")

complete <- FillIn(D1 = complete, 
                   D2 = gdb,
                   Var1 = "Conf_Notes",
                   Var2 = "Conf_Notes_gdb",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")

complete <- FillIn(D1 = complete, 
                   D2 = gdb,
                   Var1 = "Calc_Acr",
                   Var2 = "Calc_Acr_gdb",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")


# Assign APPL_IDs not digitized
df <- data.frame(Reviewer.one = c(rep('Stanley', 7), rep('Juliana', 7), rep('Rob', 7)), 
                 Reviewer.two = c(rep('Juliana', 7), rep('Rob', 7), rep('Stanley', 7)),
                 deliverable_status = c(rep('No', 21)),
                 APPL_ID = complete %>% filter(is.na(Reviewer.1)) %>% select(APPL_ID))

df$Reviewer.one <- as.character(df$Reviewer.one)
df$Reviewer.two <- as.character(df$Reviewer.two)
df$deliverable_status <- as.character(df$deliverable_status)

complete <- FillIn(D1 = complete, 
                   D2 = df,
                   Var1 = "Reviewer.1",
                   Var2 = "Reviewer.one",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")

complete <- FillIn(D1 = complete, 
                   D2 = df,
                   Var1 = "Reviewer.2",
                   Var2 = "Reviewer.two",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")

complete <- FillIn(D1 = complete, 
                   D2 = df,
                   Var1 = "Deliverable",
                   Var2 = "deliverable_status",
                   KeyVar = c("APPL_ID"),
                   KeepD2Vars = "FALSE")


# Write data to spreadsheet ----

write.xlsx(complete, "ENTER PATH HERE")

