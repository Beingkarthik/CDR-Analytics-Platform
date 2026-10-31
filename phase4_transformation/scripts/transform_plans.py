import pandas as pd

def transform_plans(df):

    df = df.drop_duplicates(subset=['plan_id'])

    df.loc[
        df['rate_per_minute_pence'] < 0,
        'rate_per_minute_pence'
    ] = 0

    df['monthly_fee_gbp'] = (
        df['monthly_fee_gbp']
        .fillna(df['monthly_fee_gbp'].mean())
    )

    return df
