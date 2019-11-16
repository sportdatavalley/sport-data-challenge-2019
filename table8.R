library(data.table)
library(ggplot2)
library(gganimate)

# race results
results <- read.csv("./data/race_results/results.csv")

# track data
ams <- read.csv('./data/courses/amsterdam_marathon.csv')
dam <- read.csv('./data/courses/dam_tot_damloop.csv')
egmond <- read.csv('./data/courses/egmond_halve_marathon.csv')
groet <- read.csv('./data/courses/groet_uit_schoorl.csv')

# track plots
plot(ams$latitude~ams$longitude)
plot(dam$latitude~dam$longitude)
plot(egmond$latitude~egmond$longitude)
plot(groet$latitude~groet$longitude)

# restrict data to most recent full marathon in Amsterdam
# this step will become a selector in a shiny app
# TODO: the variable naming is very specific, should be more generic
distance <- 42195
ams_results_all <- results[results$event_name == "amsterdam_marathon", ]
ams_results_marathon <- ams_results_all[ams_results_all$distance == distance, ]
ams_results_marathon_recent <- ams_results_marathon[ams_results_marathon$date == "2019-10-20", ]

# clean the few doubles - note: there are double hashed_names still and that's correct
ams_results_marathon_recent[c('race', 'id')] <- NULL 
ams_results_marathon_recent <- unique(ams_results_marathon_recent)

# steps for the interpolation
distance_tick <- 100

# TODO: this can be different for some events and should be more general
# steps in the distances actually observed
x_observed <- c(0, (1:8)*5000, distance)

# TODO: this can be different for some events and should be more general
# names of the columns that mark the observed times at specific distances
y_names <- c('split_5k', 'split_10k', 'split_15k', 'split_20k', 'split_25k', 'split_30k', 'split_35k', 'split_40k', 'split_finish')

# interpolation output points
xout <- (1 : floor(distance / distance_tick)) * distance_tick

# start time: time between the gun shot and the time of passing the Start point of the race
ams_results_marathon_recent$start <- ams_results_marathon_recent$gun_time_seconds - ams_results_marathon_recent$chip_time_seconds

# Currying of the in-built R interpolation function
interpolation_function <- function(df){
  approx(x_observed, y = c(0, df[y_names]), xout, method="linear")$y
}

# interpolated run times for each runner
interpolated_run_time <- t(apply(ams_results_marathon_recent, 1, interpolation_function))

# interpolated actual times for each runner (shifted by the start time)
actual_time <- interpolated_run_time + rep(ams_results_marathon_recent$start)

# function to get the position of a specific runner at a given time
get_position_at_time <- function(df, time){
  if (any(df < time)){
    return(max(which(df < time)))
  }
  return(0)
}

# function to get the level of congestion over the track at a given time
get_congestion_at_time <- function(target_time){
    
    # Currying of the function to the specific time of interest
    get_position_at_target_time <- function(df){
      
      # get the position of a runner at the target time
      position <- get_position_at_time(df, target_time) * distance_tick
      
      # if position is found, get the coordinates along the track based on distance ran
      if(position > 0){
        latitude <- unique(ams$latitude[ams$distance == max(ams$distance[ams$distance<position])])
        longitude <- unique(ams$longitude[ams$distance == max(ams$distance[ams$distance<position])])
      } else { # otherwise put them at the starting point
        latitude <- ams$latitude[1]
        longitude <- ams$longitude[1]
      }
      
      return(c(position, latitude, longitude))
  }
  
  # get the position of each runner at the target time
  position_at_target_time <- t(apply(actual_time, 1, FUN = get_position_at_target_time))
  
  # make a data.frame from the matrix
  position_df <- as.data.frame(position_at_target_time)
  
  # aggregate the position data.frame to get level of congestion at each coordinate
  aggregated_position <- aggregate(position_df$V1, position_df["V1"], length)
  
  # get the meta-data of the positions 
  unique_positions <- unique(position_df)
  
  # merge the metadata with the congestion information
  congestion <- merge(aggregated_position, unique_positions)
  
  # add the target time variable for which this was calcualted (required for the animation later)
  congestion$target_time <- target_time
  
  # drop the unnecessary column
  congestion$V1 <- NULL
  
  return(congestion)
}

# times at which congestion is calculated
time_tick <- 200
times <- (1 : floor(max(ams_results_marathon_recent$split_finish) / time_tick)) * time_tick

# TODO: make this a parLapply or a for.each to parallel-run and reduce run-time (no pun intended)
# get the congestion data at each time point for the animation
congestion_multiple <- do.call(rbind, lapply(times, get_congestion_at_time))

track_points <- do.call(rbind, lapply(times, 
                                      function(target_time){
                                        return(cbind(ams, data.frame(target_time = target_time)))
                                      }))

# create a plot of the track and add the congestion data 
plot <- ggplot(track_points, aes(x=longitude, y=latitude)) +
  geom_point(color='black') +
  geom_point(data = congestion_multiple, aes(x=V3, y=V2, size=x), color='red')

# create the animation
plot + transition_time(target_time) +
  labs(title = "Time elapsed: {frame_time}")

