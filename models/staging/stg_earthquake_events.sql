with source as (
    select 
        earthquake_id,
        event_data,
        ingested_at
    from {{source('usgs', 'earthquake_events')}}
),

flattened as (
    select 
        earthquake_id,
        event_data:properties.net::varchar as network_id,
        
        --geographic data
        event_data:geometry.coordinates[0]::float as longitude,
        event_data:geometry.coordinates[1]::float as latitude,
        event_data:geometry.coordinates[2]::float as depth_km,
        
        --time data
        to_timestamp_ntz(event_data:properties.time::number / 1000) as event_time_utc,
        to_timestamp_ntz(event_data:properties.updated::number / 1000) as update_time_utc,
        ingested_at,

        --magnitude
        event_data:properties.mag::float as magnitude,
        event_data:properties.magType::varchar as magnitude_type,

        --descriptive information
        event_data:properties.sig::number as significance,
        event_data:properties.tsunami::number as tsunami,
        event_data:properties.type::varchar as event_type,
        event_data:properties.nst::number as stations_detected,

        --less frequently collected data
        event_data:properties.alert::varchar as alert,
        event_data:properties.felt::number as dyfi_felt,
        event_data:properties.cdi::float as dyfi_cdi,
        event_data:properties.mmi::float as mmi,

from source
)

select *
from flattened
