library(shiny)
library(leaflet)
library(ggmap)
crimes_vector <- c("ARSON" = "ARSON", "ASSAULT" = "ASSAULT", "BATTERY" = "BATTERY", "BAD CHECKS" = "BAD CHECKS", "BRIBERY" = "BRIBERY", "BURGLARY" = "BURGLARY", 
                  "DISORDERLY CONDUCT" = "DISORDERLY CONDUCT", "DRIVING UNDER THE INFLUENCE" = "DRIVING UNDER THE INFLUENCE", "DRUG/NARCOTIC" = "DRUG/NARCOTIC",
                  "DRUNKENNESS" = "DRUNKENNESS", "EMBEZZLEMENT" = "EMBEZZLEMENT", "EXTORTION" = "EXTORTION", "FAMILY OFFENSES" = "FAMILY OFFENSES",
                  "FORGERY/COUNTERFEITING" = "FORGERY/COUNTERFEITING", "FRAUD" = "FRAUD", "GAMBLING" = "GAMBLING", "KIDNAPPING" = "KIDNAPPING",
                  "LARCENY/THEFT" = "LARCENY/THEFT", "LIQUOR LAWS" = "LIQUOR LAWS", "LOITERING" = "LOITERING", "MISSING PERSON" = "MISSING PERSON",
                  "NON-CRIMINAL" = "NON-CRIMINAL", "OTHER OFFENSES" = "OTHER OFFENSES", "PORNOGRAPHY/OBSCENE MAT" = "PORNOGRAPHY/OBSCENE MAT", "PROSTITUTION" = "PROSTITUTION",
                  "RECOVERED VEHICLE" = "RECOVERED VEHICLE", "ROBBERY" = "ROBBERY", "RUNAWAY" = "RUNAWAY", "SECONDARY CODES" = "SECONDARY CODES",
                  "SEX OFFENSES, FORCIBLE" = "SEX OFFENSES, FORCIBLE", "SEX OFFENSES, NON FORCIBLE" = "SEX OFFENSES, NON FORCIBLE", "STOLEN PROPERTY" = "STOLEN PROPERTY",
                  "SUICIDE" = "SUICIDE", "SUSPICIOUS OCC" = "SUSPICIOUS OCC", "TREA" = "TREA", "TRESPASS" = "TRESPASS", "VANDALISM" = "VANDALISM",
                  "VEHICLE THEFT" = "VEHICLE THEFT", "WARRANTS" = "WARRANTS", "WEAPON LAWS" = "WEAPON LAWS")
crimes_checked <- c("ASSAULT", "BATTERY", "BURGLARY", "DISORDERLY CONDUCT", "DRUG/NARCOTIC", "DRUNKENNESS", "KIDNAPPING", "LARCENY/THEFT", "LIQUOR LAWS",  "LOITERING",
                    "RECOVERED VEHICLE", "ROBBERY", "SEX OFFENSES, FORCIBLE", "SEX OFFENSES, NON FORCIBLE", "STOLEN PROPERTY", "SUSPICIOUS OCC", "TREA",
                    "TRESPASS", "VANDALISM", "VEHICLE THEFT", "WARRANTS", "WEAPON LAWS")
days_vector <- c("Sunday" = "Sunday", "Monday" = "Monday", "Tuesday" = "Tuesday", "Wednesday" = "Wednesday", "Thursday" = "Thursday", "Friday" = "Friday", "Saturday" = "Saturday")
days_checked <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday") 
periods_vector <- c("MIDNIGHT - 6:00 A.M." = "early_morning", "6:00 A.M. - NOON" = "morning", 
                    "NOON - 6:00 P.M." = "afternoon", "6:00 P.M. - MIDNIGHT" = "evening")
periods_checked <- c("early_morning", "morning", "afternoon", "evening")
plots_facets_vector <- c("day of week" , "time of day" , "crime category" )
years_vector <- c("2016", "2015", "2014", "2013", "2012", "2011", "2010", "2009", "2008", "2007", "2006", "2005", "2004", "2003")
locations_vector <- c("Union Square, San Francisco", "Park Presidio Blvd and Geary Blvd, San Francisco", "Twin Peaks, San Francisco", "Balboa Park, San Francisco",
                      "Russian Hill, San Francisco", "San Francisco State University, San Francisco", "Noriega St and 19th Ave, San Francisco", "UCSF, San Francisco",
                      "Transamerica Pyramid, San Francisco", "16th St and Mission St, San Francisco", "Chinatown, San Francisco", "Golden Gate Park, San Francisco",
                      "Ashton Ave and Ocean Ave, San Francisco", "Treasure Island, San Francisco")

shinyUI(fluidPage(
  titlePanel(h3("San Francisco Crime Map"), windowTitle = "San Francisco Crime Map"),
  sidebarLayout (
    sidebarPanel(
           textInput("address",label=h4("Enter location or click on map"),
                     value=sample(locations_vector, size=1, replace=TRUE) ),
           
           sliderInput("radius",label=h4("Radius in miles"),
                       min=0.5,max=2.0,value=1.0, step=0.5),
           actionButton("goButton", "Search", style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
           selectInput("year", label = h4("Year"), years_vector),
           checkboxGroupInput("crimes", label = h4("Crime Type"), choices = crimes_vector, selected = crimes_checked, inline = TRUE),
           checkboxGroupInput("days_of_week", label = h4("Days of Week"), choices = days_vector, selected = days_checked, inline = TRUE),
           checkboxGroupInput("time_periods", label = h4("Time Periods"), choices = periods_vector, selected = periods_checked, inline = TRUE),
           selectInput("plots_facets", label = h4("Facet density maps and bar plots by"), plots_facets_vector),
           HTML('<a href="https://github.com/carlosror/chicago_crimes" target="_blank"><img src = "github_icon.png" alt = "xyz"></a>
                 <a href="https://twitter.com/LrnDataScience" target="_blank"><img src = "twitter_icon.png" alt = "xyz"></a>')
    ),
    mainPanel(
        tabsetPanel(
            tabPanel("Map", leafletOutput("map",width="auto",height="640px")),
            tabPanel("Data", dataTableOutput("DataTable")),
            tabPanel("Barplots", plotOutput("barplots", width = "auto", height="640px")),
            tabPanel("Density Maps (Patience)", plotOutput("density_maps", width = "auto", height="640px")),
            tabPanel("Table", verbatimTextOutput("table")),
            tabPanel("Notes", htmlOutput("notes"))
            # tabPanel("Debug", verbatimTextOutput("debug"))
        )
    )
)))