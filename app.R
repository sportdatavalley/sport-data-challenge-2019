library(shiny)
library(ggplot2)
library(gganimate)
library(shinycustomloader)
library(foreach)
library(doParallel)

load("precalculated_congestion_data.RData")
source("congestion.R")

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Congestion animation"),
  
  fluidPage(
    fluidRow(
      column(3, selectInput("event", "Select event:", 
                            choices=unique(all_congestions$event))),
      column(3, uiOutput("dateSelector")),
      column(3, numericInput("distanceTick", "Distance tick:", 100, min = 100, max = 2000, step = 100)),
      column(3, numericInput("timeTick", "Time tick:", 200, min = 100, max = 1200, step = 100)),
      style = "min-height: 20px;padding: 19px;margin-bottom: 20px;background-color: #f5f5f5;border: 1px solid #e3e3e3;border-radius: 4px;-webkit-box-shadow: inset 0 1px 1px rgba(0,0,0,.05);box-shadow: inset 0 1px 1px rgba(0,0,0,.05);"
    ),
    # fluidRow(column(8, imageOutput("congestionPlot")))
    shinycustomloader::withLoader(imageOutput("congestionPlot"))
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  output$dateSelector <- renderUI({
    selectInput("date", "Select date:", 
                choices=unique(all_congestions$date[all_congestions$event == input$event]))
    
  })
  
  output$congestionPlot <- renderImage({
    
    require(input$event)
    require(input$date)
    require(input$distanceTick)
    require(input$timeTick)

    precalculated_distance_ticks <- unique(all_congestions$distance_tick[all_congestions$event == as.character(input$event) & all_congestions$date == as.character(input$date)])
    precalculated_time_ticks <- unique(all_congestions$time_tick[all_congestions$event == as.character(input$event) & all_congestions$date == as.character(input$date)])
    
    # check if all inputs are already loaded
    if (!is.null(input$date)) {
      
      # if the required setup is not pre-calculated, calculate it on the fly and add it to the precalculated things
      if (!((input$distanceTick %in% precalculated_distance_ticks) & (input$timeTick %in% precalculated_time_ticks))) {
        
        # register the cores for parallel computing
        registerDoParallel(cores=parallel::detectCores() - 1)
        
        # race results
        results <- read.csv("./data/race_results/results.csv", stringsAsFactors = FALSE)
        
        # TODO: this list may have to be extended if there are other events in the complete dataset
        # track data with names corresponding to the events
        tracks <- list(amsterdam_marathon = read.csv('./data/courses/amsterdam_marathon.csv', stringsAsFactors = FALSE),
                       dam_tot_damloop = read.csv('./data/courses/dam_tot_damloop.csv', stringsAsFactors = FALSE),
                       egmond_halve_marathon = read.csv('./data/courses/egmond_halve_marathon.csv', stringsAsFactors = FALSE),
                       groet_uit_schoorl_run = read.csv('./data/courses/groet_uit_schoorl.csv', stringsAsFactors = FALSE))
        
        congestion_info <- calculate_congestion(event = input$event, 
                                                date = input$date,
                                                distance_tick = input$distanceTick,
                                                time_tick = input$timeTick,
                                                results = results,
                                                tracks = tracks)
        all_track_points <- rbind(all_track_points, congestion_info[[1]])
        all_congestions <- rbind(all_congestions, congestion_info[[2]])
        
        precalculated_distance_ticks <- unique(all_congestions$distance_tick[all_congestions$event == as.character(input$event) & all_congestions$date == as.character(input$date)])
        precalculated_time_ticks <- unique(all_congestions$time_tick[all_congestions$event == as.character(input$event) & all_congestions$date == as.character(input$date)])
        
        save(list = c("all_track_points", "all_congestions"), file = "precalculated.RData")

      }
        
      track_points <- all_track_points[all_track_points$event == input$event & 
                                         all_track_points$date == input$date & 
                                         all_track_points$distance_tick == input$distanceTick & 
                                         all_track_points$time_tick == input$timeTick, ]
      
      congestion_multiple <- all_congestions[all_congestions$event == input$event & 
                                               all_congestions$date == input$date & 
                                               all_congestions$distance_tick == input$distanceTick & 
                                               all_congestions$time_tick == input$timeTick, ]
      
      # A temp file to save the output.
      # This file will be removed later by renderImage
      outfile <- tempfile(fileext='.gif')
      
      # create a plot of the track and add the congestion data 
      animation <- ggplot(track_points, aes(x=longitude, y=latitude)) +
        geom_point(color='black') +
        geom_point(data = congestion_multiple, aes(x=V3, y=V2, size=x), color='red')
      
      # create the animation
      anim_save("outfile.gif",
                animation + transition_time(target_time) +
                  labs(title = "Time elapsed: {frame_time}"))
      
      # Return a list containing the filename
      list(src = "outfile.gif", contentType = 'image/gif')
      
    } else {
      NULL
    }
  }, deleteFile = TRUE)
}

# Run the application 
shinyApp(ui = ui, server = server)
