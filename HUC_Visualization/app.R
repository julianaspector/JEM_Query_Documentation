# This Shiny app will be used to locate spatial information for watersheds of interest from Water49 database.

library(shiny)
library(arcgisbinding)
library(sf)
library(leaflet)


# do this before using arcgisbinding pkg

arc.check_product()

# open huc_10 and huc_12 from Water 49
#Replace USERNAME with appropriate user name
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


# make hu_10 and hu_12 spatial data accessible
hu_10 <- arc.select(object = hu_10)
hu_12 <- arc.select(object = hu_12)
hu_8 <- arc.select(object = hu_8)

# convert to sf objects
hu_10 <- arc.data2sf(hu_10)
hu_12 <- arc.data2sf(hu_12)
hu_8 <- arc.data2sf(hu_8)

# make objects in same coordinate system

hu_10 <- st_transform(hu_10, crs = 4326)
hu_12 <- st_transform(hu_12, crs = 4326)
hu_8 <- st_transform(hu_8, crs = 4326)


# open PODs from Water49
POD <-
    arc.open(
        "C:/Users/USERNAME/AppData/Roaming/ESRI/Desktop10.6/ArcCatalog/Connection to water49db.sde/WBGIS.POINTS_OF_DIVERSION"
    )


# make PODs accessible
POD <- arc.select(object = POD)

POD <- arc.data2sf(POD)

POD <- st_buffer(POD, dist = 0)

POD <- st_transform(POD, crs = 4326)

ui <- fluidPage(# Application title
    titlePanel("Watershed Locator Tool"),
    
    # Sidebar with radio buttons and option select
    sidebarLayout(
        sidebarPanel(
            radioButtons(
                "HUC_choice",
                "Please choose the Hydrologic Unit Code system:",
                choices = c("HUC-10", "HUC-12", "HUC-8")
            ),
            helpText("Search for watershed of interest"),
            uiOutput("HUC10orHUC12")
        ),
        
        # Show a map with watershed areas
        mainPanel(leafletOutput("map_ws"))
    ))

server <- function(input, output, session) {
    output$HUC10orHUC12 <- renderUI({
        if (input$HUC_choice == "HUC-10") {
            selectInput("HUC10Choices",
                        label = "HUC 10 NAMES",
                        choices = sort(hu_10$NAME))
        }
        else if (input$HUC_choice == "HUC-8") {
            selectInput("HUC8Choices",
                        label = "HUC 8 NAMES",
                        choices = sort(hu_8$NAME))
        }
        else {
            selectInput("HUC12Choices",
                        label = "HUC 12 NAMES",
                        choices = sort(hu_12$NAME))
        }
    })
    
    output$map_ws <- renderLeaflet({
        leaflet("map_ws") %>% addProviderTiles("Stamen.TonerLite") %>%
            setView(lat = 36.778259,
                    lng = -119.417931,
                    zoom = 5)
    })
    
    observe({
        map <- leafletProxy("map_ws") %>%
            clearShapes() %>%
            addPolygons(
                data = subset(hu_10, hu_10$NAME == input$HUC10Choices),
                popup =  ~ paste(
                    "Object ID:",
                    as.character(OBJECTID),
                    "<br>",
                    "HUC-10 NAME:",
                    as.character(NAME)
                )
            )
    })
    observe({
        map <- leafletProxy("map_ws") %>%
            clearShapes() %>%
            addPolygons(
                data = subset(hu_12, hu_12$NAME == input$HUC12Choices),
                popup =  ~ paste(
                    "Object ID:",
                    as.character(OBJECTID),
                    "<br>",
                    "HUC-12 NAME:",
                    as.character(NAME)
                )
            )
    })
    observe({
        map <- leafletProxy("map_ws") %>%
            clearShapes() %>%
            addPolygons(
                data = subset(hu_8, hu_8$NAME == input$HUC8Choices),
                popup =  ~ paste(
                    "Object ID:",
                    as.character(OBJECTID),
                    "<br>",
                    "HUC-8 NAME:",
                    as.character(NAME)
                )
            )
    })
    
}
# Run the application
shinyApp(ui = ui, server = server)