from pathlib import Path
import os

import pandas as pd
import psycopg2


PROCESSED_DIR = Path("data/processed")
TEMP_DIR = Path("data/temp")

TEMP_DIR.mkdir(
    parents=True,
    exist_ok=True
)


DB_CONFIG = {
    "dbname": "nyc_taxi"
}


DATABASE_COLUMNS = [

    "vendor_id",

    "pickup_datetime",
    "dropoff_datetime",

    "pickup_date",

    "pickup_location_id",
    "dropoff_location_id",

    "payment_type",

    "passenger_count",

    "trip_distance",
    "trip_duration_minutes",
    "avg_speed_mph",

    "fare_amount",
    "extra",
    "mta_tax",
    "tip_amount",
    "tolls_amount",
    "improvement_surcharge",
    "total_amount",

    "congestion_surcharge",
    "airport_fee",
    "cbd_congestion_fee",

    "pickup_hour",
    "pickup_weekday_num",

    "is_weekend",
    "is_rush_hour",

    "revenue_per_mile",
    "revenue_per_minute",
    "tip_percentage",

    "valid_tip_analysis",
    "valid_revenue_efficiency"
]


def prepare_dataframe(df):

    rename_map = {
        "VendorID": "vendor_id",
        "tpep_pickup_datetime": "pickup_datetime",
        "tpep_dropoff_datetime": "dropoff_datetime",
        "PULocationID": "pickup_location_id",
        "DOLocationID": "dropoff_location_id",
        "Airport_fee": "airport_fee"
    }

    df = df.rename(
        columns=rename_map
    )

    # Optional TLC column
    if "cbd_congestion_fee" not in df.columns:
        df["cbd_congestion_fee"] = pd.NA


    # ============================================
    # PostgreSQL integer-compatible columns
    # ============================================

    nullable_integer_columns = [
        "vendor_id",
        "pickup_location_id",
        "dropoff_location_id",
        "payment_type",
        "passenger_count",
        "pickup_hour",
        "pickup_weekday_num",
    ]

    for col in nullable_integer_columns:
        df[col] = pd.to_numeric(
            df[col],
            errors="coerce"
        ).astype("Int64")


    # ============================================
    # PostgreSQL boolean-compatible columns
    # ============================================

    boolean_columns = [
        "is_weekend",
        "is_rush_hour",
        "valid_tip_analysis",
        "valid_revenue_efficiency",
    ]

    for col in boolean_columns:
        df[col] = df[col].astype(bool)


    # ============================================
    # Date
    # ============================================

    df["pickup_date"] = pd.to_datetime(
        df["pickup_date"]
    ).dt.date


    return df[DATABASE_COLUMNS]


def copy_to_postgres(
    conn,
    csv_path
):

    columns = ", ".join(
        DATABASE_COLUMNS
    )

    sql = f"""
        COPY fact_trips (
            {columns}
        )
        FROM STDIN
        WITH (
            FORMAT CSV,
            HEADER TRUE,
            NULL ''
        )
    """

    with conn.cursor() as cursor:

        with open(
            csv_path,
            "r"
        ) as file:

            cursor.copy_expert(
                sql,
                file
            )

    conn.commit()


def load_file(
    conn,
    parquet_path
):

    print(
        f"\nLoading {parquet_path.name}"
    )

    df = pd.read_parquet(
        parquet_path
    )

        # ============================================
    # Enforce source file month
    # ============================================

    # Example:
    # yellow_tripdata_2025-01_clean.parquet
    # -> 2025-01

    file_month = parquet_path.name.split(
        "_"
    )[2][:7]

    expected_period = pd.Period(
        file_month,
        freq="M"
    )

    pickup_period = (
        df["tpep_pickup_datetime"]
        .dt.to_period("M")
    )

    before_filter = len(df)

    df = df[
        pickup_period == expected_period
    ].copy()

    removed_wrong_month = (
        before_filter - len(df)
    )

    print(
        f"Removed {removed_wrong_month:,} "
        f"records outside {file_month}"
    )

    df = prepare_dataframe(
        df
    )

    temp_csv = (
        TEMP_DIR
        / f"{parquet_path.stem}.csv"
    )

    try:

        print(
            "Creating temporary CSV..."
        )

        df.to_csv(
            temp_csv,
            index=False,
            na_rep=""
        )

        print(
            "Bulk copying to PostgreSQL..."
        )

        copy_to_postgres(
            conn,
            temp_csv
        )

        print(
            f"Loaded {len(df):,} rows."
        )

    except Exception:

        conn.rollback()

        raise

    finally:

        if temp_csv.exists():

            os.remove(
                temp_csv
            )

            print(
                "Temporary CSV deleted."
            )

def main():

    files = sorted(
        PROCESSED_DIR.glob(
            "yellow_tripdata_*_clean.parquet"
        )
    )


    print(
        f"Found {len(files)} processed files."
    )


    conn = psycopg2.connect(
        **DB_CONFIG
    )


    try:

        for file in files:

            load_file(
                conn,
                file
            )

    finally:

        conn.close()


if __name__ == "__main__":
    main()