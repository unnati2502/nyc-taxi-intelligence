from pathlib import Path
import pandas as pd

from extract import (
    get_trip_files,
    extract_trip_data,
    extract_zone_lookup
)

from transform import transform_trip_data


PROCESSED_DIR = Path("data/processed")

PROCESSED_DIR.mkdir(
    parents=True,
    exist_ok=True
)


def process_file(file_path, zones):

    raw_df = extract_trip_data(
        file_path
    )

    clean_df = transform_trip_data(
        raw_df,
        zones
    )

    output_name = (
        file_path.stem
        + "_clean.parquet"
    )

    output_path = (
        PROCESSED_DIR
        / output_name
    )

    clean_df.to_parquet(
        output_path,
        index=False
    )

    print(
        f"\nSaved: {output_path}"
    )

    return {
        "file": file_path.name,
        "raw_rows": len(raw_df),
        "clean_rows": len(clean_df)
    }


def main():

    files = get_trip_files()

    zones = extract_zone_lookup()

    results = []

    for file in files:

        print("\n")
        print("=" * 60)
        print(f"PROCESSING {file.name}")
        print("=" * 60)

        result = process_file(
            file,
            zones
        )

        results.append(result)


    summary = pd.DataFrame(results)

    summary["removed_rows"] = (
        summary["raw_rows"]
        - summary["clean_rows"]
    )

    summary["retention_pct"] = (
        summary["clean_rows"]
        / summary["raw_rows"]
        * 100
    )


    print("\n")
    print("=" * 60)
    print("ETL PIPELINE SUMMARY")
    print("=" * 60)

    print(summary.to_string(index=False))


    summary.to_csv(
        "data/processed/etl_summary.csv",
        index=False
    )


if __name__ == "__main__":
    main()