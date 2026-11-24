# Geothermal Energy & Earthquakes

## Project Overview
This project explores how geothermal power plant operators can use data to monitor earthquake activity near their facilities, identify changes in earthquake patterns, and prioritize facilities for further risk assessment.  Built with Python, Snowflake, dbt, and GitHub Actions, the project develops an automated data pipeline for collecting, transforming, and analyzing earthquake data from the United States Geological Survey (USGS), and combines it geothermal power plant data to understand earthquake risks for each plant.

## Data Sources
### Core Data Sources
1. [USGS Earthquake API](https://earthquake.usgs.gov/fdsnws/event/1/):
   - GeoJSON Data: Provides event-level earthquake data which serves as the primary source for earthquake event records.
   - QuakeML Data: Provides detailed seismic observations data which serves to enrich the event-level data. 
3. [EIA Power Plant and Generator Data](https://www.eia.gov/electricity/data/eia860/): Provides information about power plants and generators operating in the United States which serves to establish the relationship between the geothermal plants and earthquakes.
   
### Supplemental Data Sources
1. [Magnitude Types Table](https://www.usgs.gov/programs/earthquake-hazards/magnitude-types): Provides the base of an additional seeded table about earthquake magnitudes.
2. [Flinn-Engdahl Regions](https://www.isc.ac.uk/standards/FEregions/): Provides the base of an additional seeded table about seismic regions.
3. [Station Query](https://service.earthscope.org/fdsnws/station/1/query?level=station&format=text): Provides the base of an additional seeded table about seismic stations.

## Pipeline Architecture
### Data Ingestion
- Daily Ingestion Script: The bulk of the data for this project is pulled from the USGS Earthquake Catalog API through a daily ingestion script written in python. GitHub Actions automates the daily ingestion workflow, using GitHub Secrets to securely manage Snowflake connection credentials. 
- Seeds: Additional information, including EIA power plant and generator datasets, was loaded into Snowflake using dbt seeds.

### Transformation
Snowflake serves as the central data warehouse for this project. dbt transformations are executed separately from the automated ingestion workflow and organize the data into four layers:
- Staging: Prepares source data for downstream transformations.
- Intermediate: Parses semi-structured earthquake data into relational datasets and prepares facility data.
- Dimensional: Organizes earthquake events, seismic observations, stations, and power plants into fact and dimension tables.
- Marts: Combines earthquake and facility data using geospatial calculations to produce event-level and daily seismic monitoring datasets.

### Data Catalog
```text
.
├── README.md
├── dbt_project.yml
├── ingestion
│   ├── earthquake_geographic_enrichment.py
│   ├── earthquake_historical_backfill.py
│   └── earthquake_ingestion.py
├── models
│   ├── dimensional
│   │   ├── __dimensional.yml
│   │   ├── dimensions
│   │   │   ├── dim_magnitude_type.sql
│   │   │   ├── dim_plant.sql
│   │   │   ├── dim_seismic_region.sql
│   │   │   └── dim_station.sql
│   │   └── facts
│   │       ├── fct_earthquake_events.sql
│   │       ├── fct_earthquake_magnitudes.sql
│   │       ├── fct_earthquake_origins.sql
│   │       └── fct_station_magnitudes.sql
│   ├── intermediate
│   │   ├── __intermediates.yml
│   │   ├── int_plant_earthquake_distance.sql
│   │   ├── int_quakeml_amplitude.sql
│   │   ├── int_quakeml_arrival.sql
│   │   ├── int_quakeml_event.sql
│   │   ├── int_quakeml_magnitude.sql
│   │   ├── int_quakeml_nearest_cities.sql
│   │   ├── int_quakeml_origin.sql
│   │   ├── int_quakeml_parsed.sql
│   │   ├── int_quakeml_pick.sql
│   │   ├── int_quakeml_station_magnitude_contribution.sql
│   │   └── int_quakeml_station_magnitudes.sql
│   ├── marts
│   │   ├── __marts.yml
│   │   └── mart_plant_earthquake_events.sql
│   └── staging
│       ├── __sources.yml
│       ├── __staging.yml
│       ├── stg_earthquake_events.sql
│       ├── stg_earthquake_geographic_enrichment.sql
│       ├── stg_eia_generators.sql
│       ├── stg_eia_plants.sql
│       └── stg_station_details.sql
├── package-lock.yml
├── packages.yml
├── requirements.txt
├── seeds
│   ├── eia_generators_2025.csv
│   ├── eia_plants_2025.csv
│   ├── flinn_engdahl_regions.csv
│   ├── magnitude_type.csv
│   └── station_details.csv
└── tests
    ├── assert_arrivals_have_valid_origins.sql
    ├── assert_arrivals_have_valid_picks.sql
    ├── assert_events_have_valid_preferred_magnitudes.sql
    ├── assert_events_have_valid_preferred_origins.sql
    ├── assert_magnitudes_have_valid_origins.sql
    ├── assert_station_magnitude_contributions_have_valid_magnitudes.sql
    ├── assert_station_magnitude_contributions_have_valid_station_magnitudes.sql
    ├── assert_station_magnitudes_have_valid_amplitudes.sql
    └── assert_station_magnitudes_have_valid_origins.sql
```

### Final Marts
- **mart_plant_earthquake_events**: One row per geothermal plant–earthquake pair within 50 kilometers. Provides earthquake characteristics, epicentral distance, seismic region, measurement uncertainty, and evaluation metadata for investigating individual events near facilities.
- **mart_plant_monitoring**: One row per geothermal plant per reporting date. Provides daily monitoring metrics, including 7-day and 30-day earthquake counts, magnitude and depth statistics, proximity measures, and the most recent earthquake within the reporting window.

## Improvements and Next Steps
### Ingestion Pipeline
- Change timeout limits to better fit new ingestion process
- Retry earthquakes with missing QuakeML
- Record ingestion metrics to better understand load times and failure points

### Overall Project
- Automate the dbt transformation and earthquake_geographic_enrichment script
- Add source freshness check and alerts for failed pipeline runs
- Convert fact models from views to incremental tables
- Enrich data with ShakeML or Pager data
