library(httr)
library(jsonlite)
library(lubridate)
library(data.table)
library(tidyverse)
library(leaflet)
library(shiny)


# Define UI for app  ----

ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  leafletOutput("figure", height = "100vh")
)

# Define server logic ----
server <- function(input, output) {
  output$figure <- renderLeaflet({
    timer <- reactiveTimer(1000000)

    timer()

    # ======Log In to Lotek======
    grant_type <- "password" ## leave as "password"##
    username <- "coatrev" ## Web Service username##
    password <- Sys.getenv("lotekpassword") ## Web Service password, stored as environmental variable on windows

    #----------from LotekLogin.R---------
    ### Login###
    login <- list(
      grant_type = grant_type,
      username = username,
      password = password
    )
    res <- POST("https://webservice.lotek.com/API/user/login", body = login, encode = "form", verbose())
    #-------------------------------

    #---from PullToken.R:--------------
    #### Trying to pull token####
    t1 <- list(
      content(res)
    )
    t2 <- t1[[1]]
    token <- as.character(t2[1])
    token
    #----------------------------------

    url <- "https://webservice.lotek.com/API"
    key <- token


    ####### POSITION DATA - ALL. No Device ID Necessary#########

    today <- Sys.Date()
    dtime <- now(tz = "CET")
    CET <- format(dtime, "%H:%M:%S")
    end <- paste0(today, "T", CET, "Z")

    # start 1 week ago
    weekago <- today - 7
    start <- paste0(weekago, "T", CET, "Z")
    # start = "2019-03-02T00:00:00Z"   ###MUST BE IN yyyy-m-dThh:mm:00z format###


    #---from DataALL.R:-------------------
    data <- paste(url, "/positions/findByDate?from=", start, "&to=", end, sep = "")

    GET(data, add_headers(Authorization = paste("Bearer", key, sep = " ")))
    positions <- GET(data, add_headers(Authorization = paste("Bearer", key, sep = " ")))

    cont <- content(positions, as = "parsed", type = "application/json")

    df <- data.frame(matrix(unlist(cont), nrow = length(cont), byrow = 20))
    tab <- as.data.table(df)
    setkey(tab, X21)

    ##### ALL COLUMNS####
    nearly <- setcolorder(
      tab,
      c("X16", "X21", "X22", "X3", "X4", "X5", "X10", "X13", "X11", "X12")
    )

    names(nearly) <- c("DevName", "Device ID", "DateTimeGMT", "Latitude", "Longitude", "Altitude[m]", "DOP", "Temperature[C]", "MainV", "BackupV", "ChannelStatus", "UploadTime", "ECEFx", "ECEFy", "ECEFz", "RxStatus", "FixDuration", "bHasTempVoltage", "DeltaTime", "FixType", "CEPradius", "CRC")

    nearly[, "Date & Time [GMT]" := parse_date_time(nearly$DateTimeGMT, orders = "ymd_HMS")]

    group1 <- setcolorder(
      nearly,
      c("DevName", "Device ID", "Date & Time [GMT]", "Latitude", "Longitude", "Altitude[m]", "DOP", "Temperature[C]", "MainV", "BackupV", "ChannelStatus", "ECEFx", "ECEFy", "ECEFz", "RxStatus", "FixDuration", "bHasTempVoltage", "DeltaTime", "FixType", "CEPradius", "CRC", "DateTimeGMT")
    )

    setkey(group1, "Device ID")



    #-----------------------------------------

    # ============ select devices/ time periods /DOP========================

    # DOP lower than 5
    group1 <- group1[group1$DOP < 5, ]

    # only real positions
    group1$Latitude <- as.numeric(group1$Latitude)
    group1$Longitude <- as.numeric(group1$Longitude)

    group1 <- group1[group1$Latitude > 1, ]

    # Local time from GMT add 1 hour in winter
    group1$localtime <- group1$`Date & Time [GMT]` + 1 * 60 * 60

    # fox names
    deviceIDs <- c("92158", "92156", "92162", "92160", "92638", "92642", "92636")


    foxnames <- data.frame(
      name = c("Thorsen", "Kaptein Jan", "Mari", "Uhcci Biret", "Murphy", "Geir", "Kate"),
      deviceID = c("92158", "92156", "92162", "92160", "92638", "92642", "92636"),
      colour = c("yellow", "lime", "blue", "cyan", "orange", "cyan", "yellow"),
      deployment = c("2021-05-19T18:00:00", "2021-11-04T22:30:00", "2021-11-05T05:30:00", "2021-11-10T22:30:00", "2022-11-08T22:30:00", "2023-10-15T02:00:00", "2023-10-19T23:00:00"),
      radius = c(4, 4, 4, 4, 4, 4, 4),
      radiuslast = c(12, 12, 12, 12, 12, 12, 12)
    )


    for (i in 1:length(deviceIDs)) {
      group1$DevName[group1$`Device ID` == deviceIDs[i]] <- foxnames$name[foxnames$deviceID == deviceIDs[i]]
      group1$colour[group1$`Device ID` == deviceIDs[i]] <- foxnames$colour[foxnames$deviceID == deviceIDs[i]]
      group1$radius[group1$`Device ID` == deviceIDs[i]] <- foxnames$radius[foxnames$deviceID == deviceIDs[i]]
      group1$radiuslast[group1$`Device ID` == deviceIDs[i]] <- foxnames$radiuslast[foxnames$deviceID == deviceIDs[i]]
      group1$deployment[group1$`Device ID` == deviceIDs[i]] <- foxnames$deployment[foxnames$deviceID == deviceIDs[i]]
    }

    # make all the non-named foxes transparent or 0 radius in points
    # 0000ffff = transparent, for some reason this only works with the polylines, not points
    # maybe with opacity?

    group1$colour[is.na(group1$colour)] <- "0000ffff"
    group1$radius[is.na(group1$radius)] <- 0
    group1$radiuslast[is.na(group1$radiuslast)] <- 0
    group1$DevName[group1$DevName == ""] <- "Test Halsbånd, ikke på rev"

    # ===================plotting===================


    uniquefox <- unique(group1[, DevName])
    map <- leaflet() %>%
      addProviderTiles(providers$Esri.WorldImagery) %>%
      setView(lat = 70.45, lng = 29.85, zoom = 8) %>%
      addScaleBar(
        position = c("bottomright"),
        options = scaleBarOptions(imperial = FALSE)
      ) %>%
      addMiniMap(
        toggleDisplay = TRUE,
        tiles = providers$Stamen.TonerLite
      )

    for (n in uniquefox) {
      foxingroup1 <- group1[DevName == n]

      map <- addPolylines(map,
        lng = foxingroup1$Longitude[foxingroup1$deployment < foxingroup1$DateTimeGMT], lat = foxingroup1$Latitude[foxingroup1$deployment < foxingroup1$DateTimeGMT], # this makes sure than only positions after deployment date are plotted
        weight = 0.5, color = foxingroup1$colour, opacity = 0.1
      )
      map <- addCircleMarkers(map,
        lng = foxingroup1$Longitude[foxingroup1$deployment < foxingroup1$DateTimeGMT], lat = foxingroup1$Latitude[foxingroup1$deployment < foxingroup1$DateTimeGMT], # this makes sure than only positions after deployment date are plotted
        popup = paste(
          foxingroup1$DevName, "<br>",
          foxingroup1$localtime, "<br>",
          "Temperatur", group1$`Temperature[C]`, "C"
        ),
        radius = foxingroup1$radius,
        stroke = FALSE,
        color = foxingroup1$colour,
        fillColor = foxingroup1$colour
      )
      recentpos <- filter(foxingroup1, DateTimeGMT == max(DateTimeGMT))

      map <- addCircleMarkers(map,
        lng = recentpos$Longitude[recentpos$deployment < recentpos$DateTimeGMT], lat = recentpos$Latitude[recentpos$deployment < recentpos$DateTimeGMT], # this makes sure than only positions after deployment date are plotted
        popup = paste(
          recentpos$DevName, "<br>",
          recentpos$localtime, "<br>",
          "Temperatur", recentpos$`Temperature[C]`, "C"
        ),
        radius = 12,
        stroke = TRUE,
        color = recentpos$colour,
        fillColor = "0000ffff",
        dashArray = 9,
        weight = 2,
        opacity = 1
      )
    }
    map
  })
}


shinyApp(ui = ui, server = server)
