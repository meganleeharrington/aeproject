select
    earthquake_id,
    flinn_engdahl_region_number,
    flinn_engdahl_region_name,
    enriched_at
from {{ source('geo', 'earthquake_geographic_enrichment') }}