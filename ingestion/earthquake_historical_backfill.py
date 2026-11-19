import requests
import os
import snowflake.connector
import json
from datetime import datetime, timedelta

def fetch_earthquakes(start_time, end_time):
    url = "https://earthquake.usgs.gov/fdsnws/event/1/query"

    params = {
        "format": "geojson",
        "starttime": start_time,
        "endtime": end_time,
        "eventtype": "earthquake",
        "orderby": "time"
    }

    response = requests.get(url, params=params, timeout=120)
    response.raise_for_status()

    return response.json()

def fetch_earthquake_count(start_time, end_time):
    url = "https://earthquake.usgs.gov/fdsnws/event/1/count"

    params = {
        "starttime": start_time,
        "endtime": end_time,
        "eventtype": "earthquake"
    }

    response = requests.get(url, params=params, timeout=120)
    response.raise_for_status()

    return int(response.text.strip())

def fetch_earthquake_details(earthquake):
    detail_url = earthquake["properties"]["detail"]

    response = requests.get(detail_url, timeout=30)
    response.raise_for_status()

    return response.json()


def fetch_quakeml(earthquake_details):
    products = earthquake_details["properties"].get("products", {})
    phase_products = products.get("phase-data", [])

    if not phase_products:
        return None

    phase_product = phase_products[0]

    contents = phase_product.get("contents", {})
    quakeml_file = contents.get("quakeml.xml")

    if not quakeml_file:
        return None

    response = requests.get(quakeml_file["url"], timeout=30)
    response.raise_for_status()

    return response.text

def connect_to_snowflake():
    connection = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        database="AEPROJECT_DB",
        schema="RAW"
    )

    return connection

def is_batch_complete(connection, batch_start, batch_end):
    query = """
        SELECT COUNT(*)
        FROM RAW.HISTORICAL_INGESTION_PROGRESS
        WHERE BATCH_START = %s
          AND BATCH_END = %s
    """

    with connection.cursor() as cursor:
        cursor.execute(query, (batch_start, batch_end))
        result = cursor.fetchone()

    return result[0] > 0

def mark_batch_complete(connection, batch_start, batch_end, earthquake_count):
    query = """
        INSERT INTO RAW.HISTORICAL_INGESTION_PROGRESS (
            BATCH_START,
            BATCH_END,
            EARTHQUAKE_COUNT
        )
        VALUES (%s, %s, %s)
    """

    with connection.cursor() as cursor:
        cursor.execute(
            query,
            (batch_start, batch_end, earthquake_count)
        )

    connection.commit()

    print(
        f"Completed batch {batch_start} to {batch_end}: "
        f"{earthquake_count} earthquakes"
    )

def process_batch(connection, batch_start, batch_end):

    # Check whether this batch has already been completed
    if is_batch_complete(connection, batch_start, batch_end):
        print(f"Skipping completed batch: {batch_start}")
        return

    # Retrieve earthquakes for the date range
    earthquakes = fetch_earthquakes(
        batch_start.isoformat(),
        batch_end.isoformat()
    )

    features = earthquakes["features"]

    expected_count = fetch_earthquake_count(
        batch_start.isoformat(),
        batch_end.isoformat()
    )

    if len(features) != expected_count:
        raise ValueError(
            f"Earthquake count mismatch for {batch_start}: "
            f"retrieved {len(features)}, expected {expected_count}"
        )

    print(
        f"Validated {len(features)} earthquakes "
        f"from {batch_start} to {batch_end}"
    )

    # Retrieve and load each earthquake
    for earthquake in features:
        details = fetch_earthquake_details(earthquake)
        quakeml = fetch_quakeml(details)

        load_historical_earthquake(
            connection,
            details,
            quakeml
        )

    # Only mark the batch complete after every earthquake succeeds
    mark_batch_complete(
        connection,
        batch_start,
        batch_end,
        len(features)
    )

def load_historical_earthquake(connection, earthquake_details, quakeml):
    earthquake_id = earthquake_details["id"]

    with connection.cursor() as cursor:
        try:
            cursor.execute("BEGIN")

            cursor.execute("""
                INSERT INTO RAW.EARTHQUAKE_EVENTS (
                    EARTHQUAKE_ID,
                    EVENT_DATA
                )
                SELECT
                    %s,
                    PARSE_JSON(%s)
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM RAW.EARTHQUAKE_EVENTS
                    WHERE EARTHQUAKE_ID = %s
                )
            """, (
                earthquake_id,
                json.dumps(earthquake_details),
                earthquake_id
            ))

            if quakeml is not None:
                cursor.execute("""
                    INSERT INTO RAW.EARTHQUAKE_QUAKEML (
                        EARTHQUAKE_ID,
                        QUAKEML_XML
                    )
                    SELECT
                        %s,
                        %s
                    WHERE NOT EXISTS (
                        SELECT 1
                        FROM RAW.EARTHQUAKE_QUAKEML
                        WHERE EARTHQUAKE_ID = %s
                    )
                """, (
                    earthquake_id,
                    quakeml,
                    earthquake_id
                ))

            cursor.execute("COMMIT")

        except Exception:
            cursor.execute("ROLLBACK")
            raise

    print(f"Processed historical earthquake {earthquake_id}")

def main():
    connection = connect_to_snowflake()

    try:
        start_date = datetime(2026, 1, 1)
        cutoff_date = datetime(2026, 11, 19, 16, 30)

        max_batches = int(os.environ.get("MAX_BATCHES", "1"))
        completed_batches = 0

        current_date = start_date

        while current_date < cutoff_date and completed_batches < max_batches:
            next_date = min(
                current_date + timedelta(days=1),
                cutoff_date
            )

            if not is_batch_complete(connection, current_date, next_date):
                process_batch(
                    connection,
                    current_date,
                    next_date
                )
                completed_batches += 1

            current_date = next_date

    finally:
        connection.close()


if __name__ == "__main__":
    main()