import pandas as pd

TIME_BAND_MAPPING = {
    'OFF PEAK': 'OFF-PEAK',
    'Off_Peak': 'OFF-PEAK',
    'off-peak': 'OFF-PEAK',
    'peak': 'PEAK'
}

def transform_rated_cdrs(df):

    df = df[df['charge_pence'] >= 0]

    df = df[df['rated_correctly_flag'] == 1]

    df = df.drop_duplicates(subset=['cdr_id'])

    df['time_band_applied'] = (
        df['time_band_applied']
        .replace(TIME_BAND_MAPPING)
        .str.upper()
    )

    return df
