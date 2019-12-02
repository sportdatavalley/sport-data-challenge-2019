library(shiny)
library(ggplot2)
library(gganimate)

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
    fluidRow(
      column(8, imageOutput("congestionPlot"))
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  output$dateSelector <- renderUI({
    selectInput("date", "Select date:", 
                choices=unique(all_congestions$date[all_congestions$event == input$event]))
    
  })
  
  output$congestionPlot <- renderPlot({
    
    require(input$date)
    
    precalculated_distance_ticks <- unique(all_congestions$distance_tick[all_congestions$event == as.character(input$event) & all_congestions$date == as.character(input$date)])
    precalculated_time_ticks <- unique(all_congestions$time_tick[all_congestions$event == as.character(input$event) & all_congestions$date == as.character(input$date)])
    
    print(input$distanceTick)
    print(precalculated_distance_ticks)
    print(input$timeTick)
    print(precalculated_time_ticks)
    
    # if the required setup is not pre-calculated, calculate it on the fly
    if (!((input$distanceTick %in% precalculated_distance_ticks) & (input$timeTick %in% precalculated_time_ticks))) {
      
      tryCatch(expr = {
        results
      },
      error = function(cond){
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
        
      },
      finally = {      
        congestion_info <- calculate_congestion(event = input$event, 
                                                date = input$date,
                                                distance_tick = input$distanceTick,
                                                time_tick = input$timeTick,
                                                results = results,
                                                tracks = tracks)
        track_points <- congestion_info[[1]]
        congestion_multiple <- congestion_info[[2]]
      })
    } else {
      track_points <- all_track_points[all_track_points$event == input$event & 
                                         all_track_points$date == input$date & 
                                         all_track_points$distance_tick == input$distanceTick & 
                                         all_track_points$time_tick == input$timeTick, ]
      
      congestion_multiple <- all_congestions[all_congestions$event == input$event & 
                                               all_congestions$date == input$date & 
                                               all_congestions$distance_tick == input$distanceTick & 
                                               all_congestions$time_tick == input$timeTick, ]
    }
    
    # create a plot of the track and add the congestion data 
    plot <- ggplot(track_points, aes(x=longitude, y=latitude)) +
      geom_point(color='black') +
      geom_point(data = congestion_multiple, aes(x=V3, y=V2, size=x), color='red')
    
    # create the animation
    plot + transition_time(target_time) +
      labs(title = "Time elapsed: {frame_time}")
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
