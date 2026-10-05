import pandas as pd
import numpy as np


REQUIRED_COLUMNS = [
    "tpep_pickup_datetime",
    "tpep_dropoff_datetime",
    "PULocationID",
    "DOLocationID",
    "passenger_count",
    "trip_distance",
    "payment_type",
    "fare_amount",
    "tip_amount",
    "tolls_amount",
    "total_amount",
]


def validate_schema(df):
    """Verify required TLC fields exist."""

    missing_columns = [
        col for col in REQUIRED_COLUMNS
        if col not in df.columns
    ]

    if missing_columns:
        raise ValueError(
            f"Missing required columns: {missing_columns}"
        )

    return True

def generate_quality_report(df):
    """Generate basic data-quality metrics before cleaning."""

    duration = (
        df["tpep_dropoff_datetime"]
        - df["tpep_pickup_datetime"]
    ).dt.total_seconds() / 60

    report = {
        "total_rows": len(df),

        "duplicate_rows": df.duplicated().sum(),

        "missing_pickup_location":
            df["PULocationID"].isna().sum(),

        "missing_dropoff_location":
            df["DOLocationID"].isna().sum(),

        "zero_or_negative_distance":
            (df["trip_distance"] <= 0).sum(),

        "negative_fare":
            (df["fare_amount"] < 0).sum(),

        "zero_or_negative_total":
            (df["total_amount"] <= 0).sum(),

        "invalid_duration":
            (duration <= 0).sum(),

        "duration_over_3_hours":
            (duration > 180).sum(),

        "extreme_total_amount":
            (df["total_amount"] > 5000).sum(),
    }

    return pd.Series(report)

def select_columns(df):

    columns = [
        "VendorID",
        "tpep_pickup_datetime",
        "tpep_dropoff_datetime",
        "passenger_count",
        "trip_distance",
        "RatecodeID",
        "PULocationID",
        "DOLocationID",
        "payment_type",
        "fare_amount",
        "extra",
        "mta_tax",
        "tip_amount",
        "tolls_amount",
        "improvement_surcharge",
        "total_amount",
        "congestion_surcharge",
        "Airport_fee",
    ]

    # Some TLC years/months may contain additional columns.
    if "cbd_congestion_fee" in df.columns:
        columns.append("cbd_congestion_fee")

    return df[columns].copy()
def engineer_features(df):

    # ---------------------------
    # Trip duration
    # ---------------------------

    df["trip_duration_minutes"] = (
        df["tpep_dropoff_datetime"]
        - df["tpep_pickup_datetime"]
    ).dt.total_seconds() / 60


    # ---------------------------
    # Date features
    # ---------------------------

    df["pickup_date"] = (
        df["tpep_pickup_datetime"].dt.date
    )

    df["pickup_year"] = (
        df["tpep_pickup_datetime"].dt.year
    )

    df["pickup_month"] = (
        df["tpep_pickup_datetime"].dt.month
    )

    df["pickup_day"] = (
        df["tpep_pickup_datetime"].dt.day
    )

    df["pickup_hour"] = (
        df["tpep_pickup_datetime"].dt.hour
    )

    df["pickup_weekday"] = (
        df["tpep_pickup_datetime"].dt.day_name()
    )

    df["pickup_weekday_num"] = (
        df["tpep_pickup_datetime"].dt.dayofweek
    )


    # ---------------------------
    # Weekend flag
    # ---------------------------

    df["is_weekend"] = (
        df["pickup_weekday_num"] >= 5
    ).astype("int8")


    # ---------------------------
    # Rush-hour flag
    # ---------------------------

    morning_rush = df["pickup_hour"].between(7, 9)

    evening_rush = df["pickup_hour"].between(16, 19)

    weekday = df["pickup_weekday_num"] < 5

    df["is_rush_hour"] = (
        weekday & (morning_rush | evening_rush)
    ).astype("int8")


    # ---------------------------
    # Average speed
    # ---------------------------

    df["avg_speed_mph"] = (
        df["trip_distance"]
        / (df["trip_duration_minutes"] / 60)
    )

    return df


def clean_trip_data(df):

    initial_rows = len(df)

    # ---------------------------------
    # Remove exact duplicates
    # ---------------------------------
    df = df.drop_duplicates()


    # ---------------------------------
    # Valid location IDs
    # ---------------------------------
    df = df[
        df["PULocationID"].notna()
        & df["DOLocationID"].notna()
    ]


    # ---------------------------------
    # Valid trip distance
    # ---------------------------------
    df = df[
        df["trip_distance"] > 0
    ]


    # ---------------------------------
    # Valid financial values
    # ---------------------------------
    df = df[
        (df["fare_amount"] > 0)
        & (df["total_amount"] > 0)
    ]


    # ---------------------------------
    # Valid trip duration
    # ---------------------------------
    df = df[
        df["trip_duration_minutes"].between(
            1,
            180
        )
    ]


    # ---------------------------------
    # Plausible average speed
    # ---------------------------------
    df = df[
        df["avg_speed_mph"].between(
            1,
            80
        )
    ]


    # ---------------------------------
    # Extreme financial anomaly
    #
    # $5,000 is intentionally generous.
    # Legitimate long-distance/out-of-NYC
    # trips remain in the dataset while
    # obvious data-entry anomalies such
    # as $325K taxi trips are removed.
    # ---------------------------------
    df = df[
        df["total_amount"] <= 5000
    ]


    final_rows = len(df)

    print("\nCleaning Summary")
    print("----------------")
    print(f"Initial rows : {initial_rows:,}")
    print(f"Final rows   : {final_rows:,}")
    print(
        f"Removed      : "
        f"{initial_rows - final_rows:,}"
    )
    print(
        f"Retention    : "
        f"{final_rows / initial_rows * 100:.2f}%"
    )

    return df

def add_zone_information(df, zones):

    pickup_zones = zones.rename(
        columns={
            "LocationID": "PULocationID",
            "Borough": "pickup_borough",
            "Zone": "pickup_zone",
            "service_zone": "pickup_service_zone",
        }
    )

    dropoff_zones = zones.rename(
        columns={
            "LocationID": "DOLocationID",
            "Borough": "dropoff_borough",
            "Zone": "dropoff_zone",
            "service_zone": "dropoff_service_zone",
        }
    )

    df = df.merge(
        pickup_zones,
        on="PULocationID",
        how="left"
    )

    df = df.merge(
        dropoff_zones,
        on="DOLocationID",
        how="left"
    )

    geo_columns = [
        "pickup_borough",
        "pickup_zone",
        "pickup_service_zone",
        "dropoff_borough",
        "dropoff_zone",
        "dropoff_service_zone"
    ]

    for col in geo_columns:
        df[col] = df[col].fillna("Unknown")

    return df

def transform_trip_data(df, zones):

    validate_schema(df)

    print("\nPre-cleaning Data Quality")
    print("-------------------------")
    print(generate_quality_report(df))

    # Select useful raw fields
    df = select_columns(df)

    # Features required for validation/cleaning
    df = engineer_features(df)

    # Remove invalid trip records
    df = clean_trip_data(df)

    # Financial analytical features
    df = engineer_financial_features(df)

    # Geographic enrichment
    df = add_zone_information(
        df,
        zones
    )

    return df


def engineer_financial_features(df):

    # ---------------------------------
    # Revenue efficiency
    # ---------------------------------

    df["revenue_per_mile"] = (
        df["total_amount"]
        / df["trip_distance"]
    )

    df["revenue_per_minute"] = (
        df["total_amount"]
        / df["trip_duration_minutes"]
    )


    # ---------------------------------
    # Tip percentage
    #
    # Only meaningful for credit-card
    # transactions because cash tips
    # are generally not captured in
    # TLC tip_amount.
    # ---------------------------------

    df["tip_percentage"] = np.where(
        (df["payment_type"] == 1)
        & (df["fare_amount"] > 0),
        (df["tip_amount"] / df["fare_amount"]) * 100,
        np.nan
    )


    # ---------------------------------
    # Analytical validity flags
    # ---------------------------------

    df["valid_tip_analysis"] = (
        (df["payment_type"] == 1)
        & (df["tip_percentage"] >= 0)
        & (df["tip_percentage"] <= 100)
    ).astype("int8")


    df["valid_revenue_efficiency"] = (
        (df["revenue_per_mile"] <= 200)
        & (df["revenue_per_minute"] <= 50)
    ).astype("int8")


    return df