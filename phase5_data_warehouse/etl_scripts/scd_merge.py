from sqlalchemy import text

def scd_type2_merge(
    connection,
    table_name,
    business_key_column,
    business_key,
    new_values,
    effective_start,
):
    """Generic SCD Type 2 helper.

    This helper expects the target table to contain:
    scd_effective_start, scd_effective_end and scd_current_flag.
    The function expires the current row and inserts a new version.
    """

    current = connection.execute(
        text(
            f"SELECT * FROM {table_name} "
            f"WHERE {business_key_column} = :bk AND scd_current_flag = TRUE"
        ),
        {"bk": business_key},
    ).mappings().first()

    if current:
        connection.execute(
            text(
                f"UPDATE {table_name} "
                f"SET scd_effective_end = :end_date, scd_current_flag = FALSE "
                f"WHERE {business_key_column} = :bk AND scd_current_flag = TRUE"
            ),
            {"end_date": effective_start, "bk": business_key},
        )

    columns = list(new_values.keys()) + [
        "scd_effective_start", "scd_effective_end", "scd_current_flag"
    ]
    values = dict(new_values)
    values.update({
        "scd_effective_start": effective_start,
        "scd_effective_end": None,
        "scd_current_flag": True,
    })

    col_sql = ", ".join(columns)
    param_sql = ", ".join(f":{c}" for c in columns)

    connection.execute(
        text(f"INSERT INTO {table_name} ({col_sql}) VALUES ({param_sql})"),
        values,
    )
