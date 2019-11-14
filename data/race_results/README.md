# Explanation of race results data

All the data is retrieved from MYLAPS Sporthive.
You can also view the data at [their website](https://results.sporthive.com/).

| column name       | type (and unit)       | description                                   | remarks |
| :------------     | :-------------------- | :-------------------------------------------- | :------ |
| id                | string                | unique id of race result                      |  |
| hashed_name       | string                | hash of athlete name                          | Due to typos in the name or people with identical names it cannot be guaranteed that one hash represents a single person |
| event_name        | string                | name of the event                             |  |
| date              | string (YYYY-MM-DD)   | date of the race                              | For some races (e.g. damloop_by_night_5_em_businessloop) the date is not correct because it happened on the day before the main event. For the main races it can be considered correct though. |
| race              | string                | the name for the race within the main event   |  |
| distance          | integer (meters)      | distance of the race in meters                | Caution: There seem to be some errors in the data. For example tcs_marathon_nederlands_kampioenschap in 2018 and some of the dam_tot_damloop races to have an erroneous distance. |
| category          | string                | the race category of the athlete              | This column can be used to determine sex and age estimate |  |
| gun_time_seconds  | float (seconds)       | Time between start of start group and finish  | Please note: There is usually a time delay between the start of the group and an athlete actually passing the start |
| chip_time_seconds | float (seconds)       | Time between passing the start and finish     |  |
| split\_\*         | float (seconds)       | Time since passing the start line             |  |
