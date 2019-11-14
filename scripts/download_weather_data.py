import os
import time
from datetime import datetime
from io import StringIO
from pathlib import Path

import pandas as pd
import requests

from constants import events, event_information

OFFLINE = True if os.environ.get('OFFLINE', 'false') == 'true' else False
KNMI_UURGEGEVENS_URL = 'http://projects.knmi.nl/klimatologie/uurgegevens/getdata_uur.cgi'


def fetch_event(event):
    event_date = datetime.strptime(event['date'], '%Y-%m-%d')
    race = event_information[event['name']]

    start_date = event_date.strftime('%Y%m%d') + '00'
    end_date = event_date.strftime('%Y%m%d') + '23'

    st = time.time()
    if OFFLINE:
        with Path(Path('.').parent, 'cached_responses', f'weather_{event["name"]}_{event["year"]}').open('r') as f:
            response_text = f.read()
    else:
        print(f'downloading...', end='\r')

        weather_stations = [stn['code'] for stn in race['nearest_weather_stations']]
        response = requests.post(
            url=KNMI_UURGEGEVENS_URL,
            data=dict(
                start=start_date,
                end=end_date,
                stns=':'.join(weather_stations)
            )
        )
        print(f'downloaded...    ')
        response_text = response.text
        with Path(Path('.').parent, 'cached_responses', f'weather_{event["name"]}_{event["year"]}').open('w') as f:
            f.write(response_text)

    skiprows = 0
    for line in response_text.splitlines():
        if line.startswith('#'):
            if line.startswith('# STN,YYYYMMDD'):
                headers = line[2:].replace(' ', '').split(',')
            skiprows += 1
        else:
            break

    df = pd.read_csv(
        filepath_or_buffer=StringIO(response_text),
        header=None,
        names=headers,
        skiprows=skiprows,
        skipinitialspace=True)

    df['event_name'] = event['name']
    df['date'] = event['date']

    return df


def fetch_events():
    df = pd.DataFrame()

    for event in events:
        print(f'fetching weather data for {event["name"]} {event["year"]}')
        event_df = fetch_event(event)
        df = pd.concat([df, event_df])

    df.to_csv(Path(Path('.').parent, 'data', 'weather', 'weather_data.csv'), index=False)



if __name__ == "__main__":
    fetch_events()
