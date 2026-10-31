import pandas as pd

FRAUD_TYPE_MAPPING = {
    'sim_box': 'SIM BOX',
    'wangiri': 'WANGIRI',
    'CLI spoofing': 'CLI SPOOFING'
}

def transform_fraud(df):

    df['fraud_type'] = (
        df['fraud_type']
        .replace(FRAUD_TYPE_MAPPING)
        .str.upper()
    )

    df = df.sort_values(
        by=['fraud_id', 'scd_version'],
        ascending=[True, False]
    )

    df = df.drop_duplicates(
        subset=['fraud_id'],
        keep='first'
    )

    return df
