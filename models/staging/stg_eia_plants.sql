select
    plant_code,
    plant_name,
    utility_id,
    utility_name,
    street_address,
    city,
    state,
    zip,
    county,
    latitude,
    longitude
from {{ ref('eia_plants_2025') }}