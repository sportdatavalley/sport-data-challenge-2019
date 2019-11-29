library(ggplot2)
library(gganimate)

load("precalculated_congestion_data.RData")

# TODO: this step will become a selector in a shiny app
selected_event <- "amsterdam_marathon"
selected_date <- "2019-10-20"
# steps for the interpolation
selected_distance_tick <- 100
# time ticks for the animation in seconds
selected_time_tick <- 200

track_points <- all_track_points[all_track_points$event == selected_event & 
                                   all_track_points$date == selected_date & 
                                   all_track_points$distance_tick == selected_distance_tick & 
                                   all_track_points$time_tick == selected_time_tick, ]
congestion_multiple <- all_congestions[all_congestions$event == selected_event & 
                                         all_congestions$date == selected_date & 
                                         all_congestions$distance_tick == selected_distance_tick & 
                                         all_congestions$time_tick == selected_time_tick, ]

# create a plot of the track and add the congestion data 
plot <- ggplot(track_points, aes(x=longitude, y=latitude)) +
  geom_point(color='black') +
  geom_point(data = congestion_multiple, aes(x=V3, y=V2, size=x), color='red')

# create the animation
plot + transition_time(target_time) +
  labs(title = "Time elapsed: {frame_time}")

