library(foreach)
library(doParallel)
source("congestion.R")

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

events <- c("amsterdam_marathon", "dam_tot_damloop", "egmond_halve_marathon", "groet_uit_schoorl_run")

precalculated <- merge(data.frame(event_name = events), unique(results[c("event_name", "date")]))
precalculated$distance_tick <- 100
precalculated$time_tick <- 200

congestion_info <- lapply(1:nrow(precalculated), 
                          function(row_id){
                            calculate_congestion(event = precalculated$event_name[row_id], 
                                                 date = precalculated$date[row_id], 
                                                 distance_tick = precalculated$distance_tick[row_id], 
                                                 time_tick = precalculated$time_tick[row_id],
                                                 results = results,
                                                 tracks = tracks)
                          })

all_track_points <- do.call(rbind, lapply(congestion_info, function(element){return(element[[1]])}))
all_congestions <- do.call(rbind, lapply(congestion_info, function(element){return(element[[2]])}))

save(list = c("all_track_points", "all_congestions"), file = "precalculated.RData")
