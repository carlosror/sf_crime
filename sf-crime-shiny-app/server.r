##################################################
# To run in RStudio: 
# Make this directory the working directory and type
# library(shiny)
# runApp(launch.browser = T)
##################################################

library(shiny) #shiny server
library(ggplot2) #bar plots
library(ggmap) #density map
library(leaflet) #clickable map
library(plyr) #possibly use later for count() function to generate frequency tables in Summary
library(readr) #read_csv(), 3x faster than read.csv()

shinyServer(function(input, output, session) {
    
    # The following lines allows for the clicking of the map to obtain coordinates
    # Implementation of this feature is what requires use of the isolate() function
    # in several places. The map is used as both an output and an input, so by using
    # isolate() we sort of break the loop.
    
    # Creating dataClicked object for storing reactive values
    dataClicked <- reactiveValues()
    
    observeEvent(input$map_click,{
        ###########################################################################
        # Function that handles clicking of map to obtain coordinates
        ###########################################################################
        dataClicked$clickedMap <- input$map_click
        lat_clicked <- dataClicked$clickedMap$lat
        lng_clicked <- dataClicked$clickedMap$lng
        updateTextInput(session, inputId = "address", value=paste(lat_clicked, ",", lng_clicked))
    })
    
    filter_data <- reactive({
        ###########################################################################
        # Filters the data based on the user's selections
        # The functions that are invoked when a user selects an output tab all call filter_data() 
        ###########################################################################
        input$goButton #reactive function has to wait for Search button (input$goButton) to be pressed
        
        #http://stackoverflow.com/questions/7825501/switch-statement-usage
        crimes <- isolate(switch(input$year, "2016" = read_csv("crimes_2016.csv"), "2015" = read_csv("crimes_2015.csv"), "2014" = read_csv("crimes_2014.csv"),
                                            "2013" = read_csv("crimes_2013.csv"), "2012" = read_csv("crimes_2012.csv"),
                                            "2011" = read_csv("crimes_2011.csv"), "2010" = read_csv("crimes_2010.csv"),
                                            "2009" = read_csv("crimes_2009.csv"), "2008" = read_csv("crimes_2008.csv"),
                                            "2007" = read_csv("crimes_2007.csv"), "2006" = read_csv("crimes_2006.csv"),
                                            "2005" = read_csv("crimes_2005.csv"), "2004" = read_csv("crimes_2004.csv"),
                                            "2003" = read_csv("crimes_2003.csv")))
        
        # Since we will be using "days" and "periods" as factors, let's convert them
        crimes$days <- crimes$days %>% as.factor()
        crimes$periods <- crimes$periods %>% as.factor()
        
        # vector of coordinates c(long, lat) from user input
        # using <<- makes the variable global
        location <<- isolate(as.numeric(geocode(input$address, source="google"))) 
        # vector of crime types from user, e.g., c("arson", "assault", "battery", ...)
        # they are the crime types selected by the user
        crimes_set <- isolate(input$crimes)
        # vector of days of week selected by user, e.g., c("weekday"), or c("weekday", "weekend"), or c("weekend")
        crimes_days <- isolate(input$days_of_week)
        # vector of crime periods, e.g., c("early_morning", "morning", "afternoon", "evening"), or some combination thereof
        crimes_periods <- isolate(input$time_periods)
        # print(crimes_periods)
        # Call function to filter data based on user inputs
        filtered_data <- data_filter(crimes, location, crimes_set, crimes_days, crimes_periods)
        # Re-order factors so that days appear in order:
        # http://www.r-bloggers.com/reorder-factor-levels-2/
        filtered_data$days <- factor(filtered_data$days, levels(filtered_data$days)[c(4, 2, 6, 7, 5, 1, 3)])
        filtered_data$periods <- factor(filtered_data$periods, levels(filtered_data$periods)[c(2, 4, 1, 3)])
        # print(table(filtered_data$days))
        # print(table(filtered_data$periods))
                
        filtered_data
    })
    
    dist_equi <- function (long1, lat1, long2, lat2) {
        ###########################################################################
        # Equirectangular approximation of distance between 2 points
        # http://www.movable-type.co.uk/scripts/latlong.html
        # Not as accurate as Haversine or Spherical Law of Cosines methods but
        # for intra-city distance computations is good enough, I think,
        # and much less computationally intensive.
        ###########################################################################
        
        R = 6371000 # radius of the Earth
        
        # Convert latitudes to radians
        theta1 = lat1 * pi / 180.0
        theta2 = lat2 * pi / 180.0
        
        # Compute difference between two points and convert to radians
        # delta_theta = (lat2 - lat1) * pi / 180.0 
        delta_theta = theta2 - theta1
        delta_lambda = (long2 - long1) * pi / 180.0
        
        x = delta_lambda * cos((theta1 + theta2)/2.0)
        y = delta_theta
        
        # Compute distance, convert it to miles and return it
        return(R * sqrt(x*x + y*y) / 1609.34)
    }
    
    data_filter <- function(crimes, location, crimes_set, crimes_days, crimes_periods) {
        ###################################################################################################################################
        # Function that subsets a crimes data frame based on the user inputs
        # Gets called by filter_data()
        #
        # Inputs:
        # crimes: a data frame of crimes
        # location: vector of coordinates c(long, lat) from user input
        # crimes_set: vector of crime types from user, e.g., c("arson", "assault", "battery", ...)
        # crimes_days: vector of days of week selected by user, e.g., c("weekday"), or c("weekday", "weekend"), or c("weekend")
        # crimes_periods: vector of crime periods, e.g., c("early_morning", "morning", "afternoon", "evening"), or some combination thereof
        # 
        # Outputs:
        # relevant_data, a subset of the original crimes data frame
        ###################################################################################################################################
        
        # Filter by distance:
        relevant_data <- subset(crimes, (dist_equi(location[1], location[2], longitude, latitude) < isolate(input$radius))) 
        # Filter by crime types
        relevant_data <- subset(relevant_data, categories %in% crimes_set) 
        # Filter by days of week
        # print(str(relevant_data))
        relevant_data <- subset(relevant_data, days %in% crimes_days) 
        # Filter by day period
        relevant_data <- subset(relevant_data, periods %in% crimes_periods) 
        
        relevant_data
    }
    output$map<-renderLeaflet({
        ###########################################################################
        # Renders Leaflet map
        # http://rstudio.github.io/leaflet/
        # This function gets called when the user clicks on the Map tab
        ###########################################################################
        
        input$goButton#reactive function has to wait for Search button (input$goButton) to be pressed
        # Fetch relevant data
        relevant_data <- filter_data()
        
        # Use some of the columns as markers for the leaflet() function
        relevant_data_markers <- relevant_data[c("date", "longitude", "latitude", "description", "address", "categories", "time")]
        zoom_value <- isolate(if (input$radius == 0.5) 15 else if (input$radius <= 1.5) 14 else 13) # set map zoom based on user-selected radius
        # Generate map
        leaflet(data = relevant_data_markers) %>% addTiles() %>% addMarkers(~longitude, ~latitude, popup=~paste("<b style='color:DarkRed;'>Location:</b>", address, "<b style='color:DarkRed;'>Crime:</b>", categories, "<b style='color:DarkRed;'>Description:</b>", description, "<b style='color:DarkRed;'>Date & Time:</b>", paste(substr(date, 1, 10), time), sep = "<br/>"), clusterOptions = markerClusterOptions()) %>% setView(location[1], location[2], zoom=zoom_value) %>% addCircles(lng = location[1], lat =location[2], radius = isolate(input$radius) * 1609.34)
    })
    
    output$DataTable <- renderDataTable({
        ###########################################################################
        # Renders interactive data table
        # This function gets called when the user clicks on the Data tab
        ###########################################################################
        
        # Fetch relevant data
        relevant_data <- filter_data()
        
        # Use relevant columns for table
        relevant_data_table <- relevant_data[c("address", "date", "description", "categories", "days")]
        relevant_data_table
    })
    
    output$barplots <- renderPlot({
        ###########################################################################
        # Renders faceted bar plots
        # "R in a Nutshell, Second Edition", Chapter 15
        # This function gets called when the user clicks on the Barplots tab
        ###########################################################################
        
        # Fetch relevant data
        relevant_data <- filter_data()
        
        # Find out top crime categories, will plot top 6 only
        categories_table_sorted <- table(relevant_data$categories) %>% sort(decreasing = TRUE)
        categories_top <- names(categories_table_sorted)
        relevant_data <- subset(relevant_data, categories %in% categories_top[1:6])
                     
        crime_barplot <- ggplot(data = relevant_data) + ggtitle(paste("Crimes reported around", isolate(input$address), "in", isolate(input$year))) # basic plot + title
        # Arrange variables in the barplot according to user-selected facets
        # http://www.cookbook-r.com/Graphs/Facets_(ggplot2)/ 
        # http://www.sthda.com/english/wiki/ggplot2-legend-easy-steps-to-change-the-position-and-the-appearance-of-a-graph-legend-in-r-software
        crime_barplot <- if (isolate(input$plots_facets[1]) == "crime category") crime_barplot + geom_bar( aes(x = periods, fill = days), position="dodge") + facet_wrap( ~ categories, ncol = 3, scales = "free_y") 
                         else if (isolate(input$plots_facets[1]) == "day of week") crime_barplot + geom_bar( aes(x = periods, fill = categories), position="dodge") + facet_grid( days ~ ., scales = "free_y") 
                         else crime_barplot + geom_bar( aes(x = days, fill = categories), position="dodge") + facet_grid( periods~., scales = "free_y" )
        # Format plot text using theme()
        crime_barplot + theme(plot.title = element_text(size = 22, face = "bold"), strip.text = element_text(size = 14), axis.text.x = element_text(size = 12), axis.title.x = element_blank(), axis.title.y = element_blank(), legend.title = element_blank())
    })
    # Summary table
    output$table <- renderPrint({
        ###########################################################################
        # Renders hierarchical text table
        # This function gets called when the user clicks on the Table tab
        ###########################################################################
        
        # Fetch relevant data
        relevant_data <- filter_data()
        
        # Find out top crime categories, will plot top 6 only
        categories_table_sorted <- table(relevant_data$categories) %>% sort(decreasing = TRUE)
        categories_top <- names(categories_table_sorted)
        relevant_data <- subset(relevant_data, categories %in% categories_top[1:6])
        # Facet same as bar plots
        ftable_row_variables <- isolate(if (input$plots_facets[1] == "day of week") c(1,2) else if(input$plots_facets[1] == "time of day") c(2:1) else c(3,2))
        # By using factor(relevant_data$categories), it tosses out all but the top 6 crime categories
        ftable(relevant_data$days, relevant_data$periods, factor(relevant_data$categories), row.vars=ftable_row_variables)

    })
    
    output$density_maps <- renderPlot({
        ###########################################################################
        # Renders faceted density maps
        # This function gets called when the user clicks on the Density Maps tab
        ###########################################################################
        
        input$goButton#reactive function has to wait for Search button (input$goButton) to be pressed
        # Fetch relevant data
        relevant_data <- filter_data()
        
        # Find out top crime categories, will plot top 6 only
        categories_table_sorted <- table(relevant_data$categories) %>% sort(decreasing = TRUE)
        categories_top <- names(categories_table_sorted)
        relevant_data <- subset(relevant_data, categories %in% categories_top[1:6])
        
        zoom_value <- isolate(if (input$radius == 0.5) 15 else if (input$radius <= 1.5) 14 else 13) # set map zoom based on user-selected radius
        # Using these zoom values, less than 1% of the locations will fall outside the map, and so ggmap()
        # will issue a warning about having removed rows containing non-finite values.
        # Given the nature of the plots, i.e., density, getting over 99% of the data plotted is enough.
        # http://stackoverflow.com/questions/28303200/stat-density2d-removed-rows-containing-non-finite-values
        
        location_map <- get_map(location = isolate(input$address), source= "google", zoom = zoom_value + 1, color = "color") %>% ggmap(extent = "panel")
        location_map <- location_map + stat_density2d(aes(x = longitude, y = latitude, fill = ..level.., alpha = ..level..), bins = 20, geom = "polygon", data = relevant_data) + scale_fill_gradient(low = "yellow", high = "red") 
        location_map <- isolate(if (input$plots_facets[1] == "crime category") location_map + facet_wrap(~ categories) else if (input$plots_facets[1] == "day of week") location_map + facet_wrap(~ days) else location_map + facet_wrap(~ periods))
        location_map <- location_map + theme(plot.title = element_text(size = 22, face = "bold"), strip.text.x = element_text(size = 16), legend.position = "none", axis.text.x = element_blank(), axis.title.x = element_blank(), axis.ticks.x = element_blank(),  axis.text.y = element_blank(), axis.title.y = element_blank(), axis.ticks.y = element_blank())
        location_map + ggtitle(paste(isolate(input$year), "crime density maps of", isolate(input$address)))
    })
    
    # Notes
    output$notes <- renderUI({includeHTML("Notes.html")})
    
    output$debug <- renderPrint({
        ###########################################################################
        # Used for debugging as needed. Does not run in production version.
        ###########################################################################
        
        # updateTextInput(session, inputId = "address", value=paste(lat_clicked, ",", lng_clicked))
        # unique(filtered_data$crimes_periods)
        mtcars$cyl <- factor(mtcars$cyl, levels = c("4","6","8"), labels = c("four","six","eight"))
        tbl <- ftable(mtcars$cyl, mtcars$vs, mtcars$am, mtcars$gear, row.vars = c(2, 4), dnn = c("Cylinders", "V/S", "Transmission", "Gears"))
        # tbl
        # ftable(Titanic, row.vars = 1:3)
        relevant_data <- filter_data()
        # Find out top crime categories, will plot top 6 only
        categories_table_sorted <- table(relevant_data$categories) %>% sort(decreasing = TRUE)
        categories_top <- names(categories_table_sorted)
        relevant_data <- subset(relevant_data, categories %in% categories_top[1:6])
        # str(relevant_data)
        ftable_row_variables <- isolate(if (input$plots_facets[1] == "day of week") c(1,2) else if(input$plots_facets[1] == "time of day") c(2:1) else c(3,2))
        ftable(relevant_data$days, relevant_data$periods, factor(relevant_data$categories), row.vars=ftable_row_variables)
    })
    
    
})