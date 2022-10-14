## SHINY APP TO AUTOMATICALLY UPDATE PLOT WITH SMALL RODENT ABUNDANCE ON COAT-HOMAGE

## the app checks if new data has been added to the COAT dataportal
## if new data has been added, the data will be downloaded and the plot on the COAT homepage will be updated with the new data


## load packages
library("shiny")
library("ckanr")
library("sciplot")
library("plotrix")
library("purrr")


## setup the connection to the data portal
COAT_url <- "https://data.coat.no/" # write here the url to the COAT data portal
COAT_key <- Sys.getenv("API_coat") # write here your API key (need to access private datasets and datasets under embargo)
# the API can be found on you page on the COAT data portal (log in and click on your name in the upper right corner of the page)
# The use of an API key allows the user to access also non-public data

ckanr_setup(url = COAT_url, key = COAT_key) # set up the ckanr-API

## dataset name
name <- "V_rodents_snaptrapping_abundance_regional" # write here the name including the version of the dataset you want to download


# Define UI for app  ----
ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  plotOutput("figure", height = "100vh", width = "100%")
)

# Define server logic ----
server <- function(input, output) {
  data <- reactivePoll(1000000, # time interval how often the app checks if there is new data on the data portal (in miliseconds) -> set it to a low value for testing
    session = NULL,

    ## function to check if there is new data -------------------
    checkFunc = function() {
      package_search(name, include_private = TRUE)$results[[1]]$num_resources # looks how many resources (data files) the dataset has
    },

    ## function to download the data and update the plot if the number of data files changed ---------------
    valueFunc = function() {
      pkg <- package_search(name, include_private = TRUE)$results[[1]] # search for the dataset and save the results
      urls <- pkg$resources %>% sapply("[[", "url") # get the urls to the files included in the dataset
      urls <- urls[!grepl("readme|coordinates|aux", urls)] # discard readme, coordinate and aux files

      ##### fetch data from COAT data portal  --------------------
      mylist <- c()
      for (i in 1:length(urls)) {
        mylist[[i]] <- ckan_fetch(urls[i],
          store = "session",
          # path = paste(dest_dir, name, filenames[i], sep = "/"),
          sep = ";",
          header = TRUE
        )
      }
      storskala <- do.call(rbind, mylist)

      #### prepare data for plotting  ------------------------
      storskala$session <- as.factor(paste(storskala$t_year, storskala$t_season, sep = "")) # add session (combination of season and year) -> not the same as t_session (trapping night)
      storskala <- storskala[is.na(storskala$t_season) == F, ] # delete observation if season is NA

      ## aggregate by area, quadrat, session
      stor <- aggregate(v_abundance ~ sn_locality + sn_site + session + v_species, data = storskala, sum, na.rm = TRUE)

      ## calculate abundance per session (per year and season)
      plotdat <- aggregate(v_abundance * 100 / 24 ~ session + v_species, data = stor, mean, na.rm = T)

      ## add date
      plotdat$date <- as.factor(substr(plotdat$session, 1, 5))
      plotdat$date <- gsub(pattern = "f", replacement = ".7", plotdat$date)
      plotdat$date <- gsub(pattern = "s", replacement = ".3", plotdat$date)

      ## calculate standard deviation
      plot.sd <- aggregate(v_abundance * 100 / 24 ~ session + v_species, data = stor, sd, na.rm = T)

      ## calculate sum
      plot.sum <- aggregate(v_abundance * 100 / 24 ~ session + v_species, data = stor, sum, na.rm = T)

      ## calculate standard error
      plot.se <- aggregate(v_abundance * 100 / 24 ~ session + v_species, data = stor, sciplot::se, na.rm = T)

      plotdat <- plotdat[order(plotdat$date), ]
      plotdat$date <- as.numeric(as.character(plotdat$date))
      colnames(plotdat)[colnames(plotdat) == "v_abundance * 100/24"] <- "v_abundance"

      ## set first and last year for plotting
      first.year <- min(storskala$t_year)
      last.year <- max(storskala$t_year)

      #### make plot -----------------------

      ## plot setup
      lty <- 1
      lwd <- 3
      col_1 <- "#C9C9C9" # myodes
      col_2 <- "#468F9B" # lemmus
      col_3 <- "#925A00" # microtus
      col_4 <- "white"


      # draw the area
      plot(plotdat$date[plotdat$v_species == "myo_ruf"], plotdat$v_abundance[plotdat$v_species == "myo_ruf"],
        ylab = "number per 100 trap nights", xlab = "", xlim = c(first.year, last.year + 1), ylim = c(-0.2, 35), cex = 1.4,
        xaxt = "n", yaxt = "n", cex.lab = 1.5, frame.plot = F, lwd = lwd, type = "n"
      )


      # lines between the points
      lines(plotdat$date[plotdat$v_species == "myo_ruf"], plotdat$v_abundance[plotdat$v_species == "myo_ruf"], lty = lty, lwd = lwd, col = col_1)
      lines(plotdat$date[plotdat$v_species == "lem_lem"], plotdat$v_abundance[plotdat$v_species == "lem_lem"], lty = lty, lwd = lwd, col = col_2)
      lines(plotdat$date[plotdat$v_species == "mic_oec"], plotdat$v_abundance[plotdat$v_species == "mic_oec"], lty = lty, lwd = lwd, col = col_3)

      # points
      points(plotdat$date[plotdat$v_species == "myo_ruf"], plotdat$v_abundance[plotdat$v_species == "myo_ruf"], col = col_1, pch = 21, cex = 2, lwd = lwd, bg = col_1)
      points(plotdat$date[plotdat$v_species == "lem_lem"], plotdat$v_abundance[plotdat$v_species == "lem_lem"], col = col_2, pch = 21, cex = 2, lwd = lwd, bg = col_2)
      points(plotdat$date[plotdat$v_species == "mic_oec"], plotdat$v_abundance[plotdat$v_species == "mic_oec"], col = col_3, pch = 21, cex = 2, lwd = lwd, bg = col_3)

      # add legend
      legend(2003.8, 30, c("Grey-sided vole", "Tundra vole", "Norwegian lemming"),
        pch = c(21, 21, 21),
        pt.bg = c(col_1, col_3, col_2), col = c(col_1, col_3, col_2), bty = "n", cex = 1.5
      )

      # add axes
      years.labels <- seq(first.year, last.year, by = 1)
      years.positions <- seq(first.year + 0.5, last.year + 0.5, by = 1)

      axis(1, at = years.positions, labels = years.labels, line = 0.5, cex.axis = 1.6)
      axis(2, at = c(0, 5, 10, 15, 20, 25, 30, 35), line = -0.1, cex.axis = 1.6)
    }
  )


  output$figure <- renderPlot({
    data()
  })
}

# Run the app ----
shinyApp(ui = ui, server = server)
