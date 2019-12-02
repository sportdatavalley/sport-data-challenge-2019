calculate_congestion <- function(event, date, distance_tick, time_tick, results, tracks){
  
  # get the track data for the selected event 
  track <- tracks[[event]]
  
  # filter the raw results based on the selection
  raw_results <- results[results$event_name == event & results$date == date, ]
  
  # track data only available for the longest distance of an event
  distance <- max(raw_results$distance)
  raw_results <- raw_results[raw_results$distance == distance, ]
  
  # clean the few doubles - note: there are double hashed_names still and that's correct
  raw_results[c('race', 'id')] <- NULL 
  raw_results <- unique(raw_results)
  
  # names of the columns that mark the observed times at specific distances are following the naming convention split_XXX
  all_observation_names <- names(results)[substr(names(results), 1, 6) == "split_"]
  
  # we are only interested in the ones with data in it
  filled_observation_names <- all_observation_names[colSums(raw_results[all_observation_names], na.rm = TRUE) > 0]
  
  # if no results are found, skip
  if (length(filled_observation_names) == 0) {return(list(track_points = NULL, congestion = NULL))}
  
  # filter out the special ones not marking a fixed distance
  observation_names <- setdiff(filled_observation_names, c('split_half', 'split_finish'))
  
  # add teh finish result back in
  y_names <- c(observation_names, 'split_finish')
  
  # remove all non-digit characters from the observation names to get the distances in km and convert it into a number then multiply by a 1000 to get the distance in meters
  x_observed <- as.numeric(unlist(lapply(observation_names, function(name){gsub(pattern = "\\D+", replacement = "", x = name)}))) * 1000
  
  # order the observation points and add start and end points
  x_observed <- c(0, x_observed[order(x_observed)], distance)
  
  # interpolation output points
  xout <- (1 : floor(distance / distance_tick)) * distance_tick
  
  # start time: time between the gun shot and the time of passing the Start point of the race
  raw_results$start <- raw_results$gun_time_seconds - raw_results$chip_time_seconds
  
  # if this information is missing, set it to 0
  if (is.null(raw_results$start)) {raw_results$start <- 0}
  raw_results$start[is.na(raw_results$start)] <- 0
  
  # Currying of the in-built R interpolation function
  interpolation_function <- function(df){
    approx(x_observed, y = c(0, df[y_names]), xout, method="linear")$y
  }
  
  # interpolated run times for each runner
  interpolated_run_time <- t(apply(raw_results, 1, interpolation_function))
  
  # interpolated actual times for each runner (shifted by the start time)
  actual_time <- interpolated_run_time + rep(raw_results$start)
  
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
        latitude <- unique(track$latitude[track$distance == max(track$distance[track$distance<position])])[1]
        longitude <- unique(track$longitude[track$distance == max(track$distance[track$distance<position])])[1]
      } else { # otherwise put them at the starting point
        latitude <- track$latitude[1]
        longitude <- track$longitude[1]
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
  times <- (1 : floor(max(raw_results$split_finish) / time_tick)) * time_tick
  
  # get the congestion data at each time point for the animation
  congestion_multiple <- do.call(rbind, foreach(target_time = times) %dopar% {get_congestion_at_time(target_time)})
  congestion_multiple$event <- event
  congestion_multiple$date <- date
  congestion_multiple$distance_tick <- distance_tick
  congestion_multiple$time_tick <- time_tick
  
  track_points <- do.call(rbind, lapply(times, 
                                        function(target_time){
                                          return(cbind(track, data.frame(target_time = target_time)))
                                        }))
  track_points$event <- event
  track_points$date <- date
  track_points$distance_tick <- distance_tick
  track_points$time_tick <- time_tick
  
  
  return(list(track_points = track_points, congestion = congestion_multiple))
}
