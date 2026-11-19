select 
    seismic_region_number,
    seismic_region_name,
    flinn_engdahl_region_number,
    flinn_engdahl_region_description
from {{ ref('flinn_engdahl_regions') }}