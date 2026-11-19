select
    f.value:id::varchar as county_fips,
    f.value:properties.NAME::varchar as county_name,
    f.value:properties.STATE::varchar as state_fips,
    to_geography(f.value:geometry) as county_geometry
from {{ source('census', 'county_boundaries') }},
lateral flatten(input => raw_geojson:features) f