import requests
import pandas as pd
from pandas.io.json import json_normalize


# URL = 'https://eventresults-api.sporthive.com/api/events/6191605479316130304/races/393896/classifications/search?count=10000&offset=0'
URL = 'https://eventresults-api.sporthive.com/api/events/6191605479316130304/races/393896/classifications/search'



def data_normalizer(obj, prefix=''):
    sep = '.' if prefix else ''
    values = {}
    if isinstance(obj, list):
        for i, val in enumerate(obj):
            values.update(data_normalizer(val, prefix=prefix + sep + str(i)))
    elif isinstance(obj, dict):
        for key, value in obj.items():
            values.update(data_normalizer(value, prefix + sep + key))
    else: # assuming single value
        values[prefix] = [obj]

    return values


count = 50
offset = 0
while True:
    print(f'Requesting offset {offset}')
    response = requests.get(URL, params=dict(count=count, offset=offset))
    data = response.json()

    is_first_run = True
    for athlete in data['fullClassifications']:
        normalized_data = data_normalizer(athlete)
        df = pd.DataFrame(normalized_data)
        with open('results.csv', 'a') as f:
            df.to_csv(f, header=is_first_run)
        is_first_run = False

    if len(data['fullClassifications']) < 50:
        break
    offset += count
