select
    earthquake_id,
    flinn_engdahl_region_number,
    flinn_engdahl_region_name,
    enriched_at
from {{ source('usgs', 'earthquake_geographic_enrichment') }}