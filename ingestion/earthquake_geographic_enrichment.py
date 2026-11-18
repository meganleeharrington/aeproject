import os
import snowflake.connector
from obspy.geodetics import FlinnEngdahl

fe = FlinnEngdahl()


def connect_to_snowflake():
    connection = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        database="AEPROJECT_DB",
        schema="RAW"
    )

    return connection

def get_unenriched_earthquakes(connection):
    query = """
        SELECT
            e.earthquake_id,
            e.latitude,
            e.longitude
        FROM AEPROJECT_DB.DEV.STG_EARTHQUAKE_EVENTS e
        WHERE e.latitude IS NOT NULL
          AND e.longitude IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM AEPROJECT_DB.RAW.EARTHQUAKE_GEOGRAPHIC_ENRICHMENT g
              WHERE g.earthquake_id = e.earthquake_id
          )
    """

    cursor = connection.cursor()

    try:
        cursor.execute(query)
        earthquakes = cursor.fetchall()
    finally:
        cursor.close()

    return earthquakes

def classify_earthquakes(earthquakes):
    classified = []

    for earthquake_id, latitude, longitude in earthquakes:
        region_number = fe.get_number(longitude, latitude)
        region_name = fe.get_region(longitude, latitude)

        classified.append((
            earthquake_id,
            region_number,
            region_name
        ))

    return classified

def insert_classified_earthquakes(connection, classified):
    if not classified:
        print("No new earthquakes to classify.")
        return

    query = """
        INSERT INTO AEPROJECT_DB.RAW.EARTHQUAKE_GEOGRAPHIC_ENRICHMENT (
            EARTHQUAKE_ID,
            FLINN_ENGDAHL_REGION_NUMBER,
            FLINN_ENGDAHL_REGION_NAME
        )
        VALUES (%s, %s, %s)
    """

    cursor = connection.cursor()

    try:
        cursor.executemany(query, classified)
        connection.commit()
        print(f"Inserted {len(classified)} earthquake classifications.")
    finally:
        cursor.close()

def main():
    connection = connect_to_snowflake()

    try:
        earthquakes = get_unenriched_earthquakes(connection)
        print(f"Found {len(earthquakes)} earthquakes needing enrichment.")

        classified = classify_earthquakes(earthquakes)

        insert_classified_earthquakes(connection, classified)

    finally:
        connection.close()


if __name__ == "__main__":
    main()