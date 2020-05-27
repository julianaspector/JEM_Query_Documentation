# JEM Query Tool Documentation

## About JEM Query Tool
This tool was developed to support place of use mapping effort for Division of Water Rights at State Water Resource Control Board. The JEM Query can determine points of diversion within a defined watershed area and download available documents for related water right records from Electronic Water Right Management System (eWRIMS). JEM Query can also determine if previously scanned and georeferenced place of use (POU) maps are available for water rights of interest. After user has identified any eWRIMS documents that contain maps, JEM Query creates a list of water right application IDs that will require investigation in water rights records room to determine if POU maps are available on file. Finally, the JEM Query can generate a summary table of water right information for records of interest based on eWRIMS flat files.

## Script Versions
There are two versions of JEM Query script:
- JEM_Query_Local.R: Allows user to define watershed boundary based on locally available shapefiles.
- JEM_Query_Water49_Access.R: Watershed boundary is defined by a SQL query within Water49 on State Water Resource Control Board's ArcGIS server.

## Other helpful scripts
The following scripts were developed as strategies to classify if eWRIMS documents were likely to contain maps. Currently eWRIMS does not designate in database if POU maps are available.
- Image_Entropy_Filtering_Script.py
- Machine_Learning_Recognize_Docs_Maps.py (developed based on [Image Detection from scratch in keras tutorial](https://towardsdatascience.com/image-detection-from-scratch-in-keras-f314872006c9)

Other useful tools include:
- HUC_Visualization.app: Allows user to visualize hydrologic unit code boundaries in web application
- PDF_to_JPEG_Conversion_Script.R: Allows user to batch convert PDF documents to JPEG format for image processing.

## Documentation
Documentation (JEM_Query_Documentation.Rmd) was developed in learnr platform. To view documentation in application mode, you will need to install [learnr](https://rstudio.github.io/learnr/index.html). Install the learnr package from CRAN as following these [instructions](https://rstudio.github.io/learnr/index.html#Getting_Started).
