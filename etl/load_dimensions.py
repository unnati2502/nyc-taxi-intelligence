import pandas as pd
from sqlalchemy import create_engine


DATABASE_URL = "postgresql+psycopg2://localhost/nyc_taxi"

engine = create_engine(DATABASE_URL)


# ============================================
# ZONE DIMENSION
# ============================================

zones = pd.read_csv(
    "data/raw/taxi_zone_lookup.csv"
)

zones = zones.rename(
    columns={
        "LocationID": "location_id",
        "Borough": "borough",
        "Zone": "zone",
        "service_zone": "service_zone"
    }
)

zones.to_sql(
    "dim_zone",
    engine,
    if_exists="append",
    index=False,
    method="multi"
)

print(
    f"Loaded {len(zones):,} zones."
)