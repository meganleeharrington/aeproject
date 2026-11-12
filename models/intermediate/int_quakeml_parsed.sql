{{ config(materialized='table') }}

select
    earthquake_id,
    parse_xml(quakeml_xml) AS parsed_xml,
    ingested_at
from {{ source('usgs', 'earthquake_quakeml') }}