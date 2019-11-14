# Explanation of weather data

The weather data is retrieved from KNMI.
[This](https://www.knmi.nl/kennis-en-datacentrum/achtergrond/data-ophalen-vanuit-een-script) website explains how the data can be retrieved.
For each race the nearest weather stations were selected.
In [this file](../../scripts/constants.py) you can see which weather stations are used for which event.

In each API response KNMI provides a legend that explains the data.
this legend is included at the bottom of this document.

We added two columns to the raw KNMI data.
Those are explained here:

| column name       | type (and unit)       | description                                   | remarks |
| -------------     | --------------------- | --------------------------------------------- | ------- |
| event_name        | string                | name of the event                             |  |
| date              | string (YYYY-MM-DD)   | date of the race                              | For some races (e.g. damloop_by_night_5_em_businessloop) the date is not correct because it happened on the day before the main event. For the main races it can be considered correct though. |
