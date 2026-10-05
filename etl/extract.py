from pathlib import Path
import pandas as pd


RAW_DATA_DIR = Path("data/raw")


def get_trip_files(data_dir=RAW_DATA_DIR):
    """Return all Yellow Taxi parquet files in chronological order."""
    
    files = sorted(data_dir.glob("yellow_tripdata_*.parquet"))

    if not files:
        raise FileNotFoundError(
            f"No Yellow Taxi parquet files found in {data_dir}"
        )

    return files


def extract_trip_data(file_path):
    """Read a Yellow Taxi parquet file."""
    
    print(f"Extracting: {file_path.name}")

    df = pd.read_parquet(file_path)

    print(f"Rows extracted: {len(df):,}")

    return df


def extract_zone_lookup(data_dir=RAW_DATA_DIR):
    """Read NYC TLC taxi-zone lookup table."""

    path = data_dir / "taxi_zone_lookup.csv"

    if not path.exists():
        raise FileNotFoundError(
            f"Taxi zone lookup not found: {path}"
        )

    zones = pd.read_csv(path)

    return zones


if __name__ == "__main__":

    files = get_trip_files()

    print(f"\nFound {len(files)} trip files:\n")

    for file in files:
        print(file.name)

    sample = extract_trip_data(files[0])

    print("\nColumns:")
    print(sample.columns.tolist())