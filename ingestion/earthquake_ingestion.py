import requests
import os
import snowflake.connector
import json
from datetime import datetime, timedelta, timezone

def fetch_earthquakes(updated_after, min_magnitude=4.5):
    url = "https://earthquake.usgs.gov/fdsnws/event/1/query"

    params = {
        "format": "geojson",
        "updatedafter": updated_after.isoformat(),
        "minmagnitude": min_magnitude,
        "orderby": "time",
        "eventtype": "earthquake"
    }

    response = requests.get(url, params=params, timeout=30)
    response.raise_for_status()

    return response.json()

def fetch_earthquake_details(earthquake):
    """
    Retrieve detailed JSON for a single earthquake.
    """

    detail_url = earthquake["properties"]["detail"]

    response = requests.get(detail_url, timeout=30)
    response.raise_for_status()

    return response.json()

def fetch_quakeml(earthquake_details):
    """
    Retrieve QuakeML data from an earthquake's phase-data product.
    Returns XML content as a string, or None if unavailable.
    """

    products = earthquake_details["properties"].get("products", {})
    phase_products = products.get("phase-data", [])

    if not phase_products:
        return None

    phase_product = phase_products[0]

    contents = phase_product.get("contents", {})
    quakeml_file = contents.get("quakeml.xml")

    if not quakeml_file:
        return None

    quakeml_url = quakeml_file["url"]

    response = requests.get(quakeml_url, timeout=30)
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

def get_last_successful_run(connection):
    query = """
        SELECT LAST_SUCCESSFUL_RUN
        FROM RAW.INGESTION_CONTROL
        WHERE PIPELINE_NAME = %s
    """

    with connection.cursor() as cursor:
        cursor.execute(query, ("USGS_EARTHQUAKES",))
        result = cursor.fetchone()

    if result is None:
        raise ValueError(
            "No ingestion checkpoint found for USGS_EARTHQUAKES"
        )

    return result[0]

def update_last_successful_run(connection, checkpoint_time):
    query = """
        UPDATE RAW.INGESTION_CONTROL
        SET
            LAST_SUCCESSFUL_RUN = %s,
            UPDATED_AT = CURRENT_TIMESTAMP()
        WHERE PIPELINE_NAME = %s
    """

    with connection.cursor() as cursor:
        cursor.execute(
            query,
            (checkpoint_time, "USGS_EARTHQUAKES")
        )

        if cursor.rowcount != 1:
            raise ValueError(
                "Expected exactly one ingestion checkpoint row"
            )

    connection.commit()

    print(f"Updated ingestion checkpoint to {checkpoint_time}")

def load_earthquake_to_snowflake(connection, earthquake_details, quakeml):
    earthquake_id = earthquake_details["id"]

    with connection.cursor() as cursor:
        try:
            # Start a transaction
            cursor.execute("BEGIN")

            # Insert or update earthquake JSON
            cursor.execute("""
                MERGE INTO RAW.EARTHQUAKE_EVENTS AS target
                USING (
                    SELECT
                        %s AS EARTHQUAKE_ID,
                        PARSE_JSON(%s) AS EVENT_DATA
                ) AS source
                ON target.EARTHQUAKE_ID = source.EARTHQUAKE_ID

                WHEN MATCHED THEN
                    UPDATE SET
                        target.EVENT_DATA = source.EVENT_DATA,
                        target.INGESTED_AT = CURRENT_TIMESTAMP()

                WHEN NOT MATCHED THEN
                    INSERT (EARTHQUAKE_ID, EVENT_DATA)
                    VALUES (
                        source.EARTHQUAKE_ID,
                        source.EVENT_DATA
                    )
            """, (
                earthquake_id,
                json.dumps(earthquake_details)
            ))

            # Insert or update QuakeML, if available
            if quakeml is not None:
                cursor.execute("""
                    MERGE INTO RAW.EARTHQUAKE_QUAKEML AS target
                    USING (
                        SELECT
                            %s AS EARTHQUAKE_ID,
                            %s AS QUAKEML_XML
                    ) AS source
                    ON target.EARTHQUAKE_ID = source.EARTHQUAKE_ID

                    WHEN MATCHED THEN
                        UPDATE SET
                            target.QUAKEML_XML = source.QUAKEML_XML,
                            target.INGESTED_AT = CURRENT_TIMESTAMP()

                    WHEN NOT MATCHED THEN
                        INSERT (EARTHQUAKE_ID, QUAKEML_XML)
                        VALUES (
                            source.EARTHQUAKE_ID,
                            source.QUAKEML_XML
                        )
                """, (
                    earthquake_id,
                    quakeml
                ))

            # Commit both changes together
            cursor.execute("COMMIT")

        except Exception:
            # Undo both changes if either operation fails
            cursor.execute("ROLLBACK")
            raise

    print(f"Loaded earthquake {earthquake_id} into Snowflake")

def main():
    # Capture the beginning of this ingestion run
    run_start = datetime.now(timezone.utc)

    # Connect to Snowflake
    connection = connect_to_snowflake()

    successful = 0
    failed = 0

    try:
        checkpoint = get_last_successful_run(connection)
        print(f"Last successful checkpoint: {checkpoint}")

        # Recheck updates from five minutes before the checkpoint
        query_start = checkpoint - timedelta(minutes=5)
        print(f"Querying updates since: {query_start}")

        earthquakes = fetch_earthquakes(query_start)

        features = earthquakes["features"]
        print(f"Retrieved {len(features)} updated earthquakes")

        # Process each earthquake
        for earthquake in features:
            earthquake_id = earthquake["id"]

            try:
                details = fetch_earthquake_details(earthquake)
                quakeml = fetch_quakeml(details)

                load_earthquake_to_snowflake(
                    connection,
                    details,
                    quakeml
                )

                successful += 1

            except Exception as error:
                failed += 1
                connection.rollback()
                print(f"Failed to process {earthquake_id}: {error}")

        # Advance checkpoint only if all earthquakes succeeded
        if failed == 0:
            update_last_successful_run(connection, run_start)
        else:
            print(
                "Checkpoint not updated because "
                f"{failed} earthquakes failed."
            )

    finally:
        connection.close()

    print("\nIngestion complete")
    print(f"Successful: {successful}")
    print(f"Failed: {failed}")


if __name__ == "__main__":
    main()