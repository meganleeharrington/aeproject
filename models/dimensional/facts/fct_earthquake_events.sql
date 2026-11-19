with amplitude_count as (
    select earthquake_id,
        count(amplitude_id) as amplitude_count
    from {{ ref('int_quakeml_amplitude') }}
    group by earthquake_id
),

magnitude_count as (
    select earthquake_id,
        count(magnitude_id) as magnitude_count
    from {{ ref('int_quakeml_magnitude') }}
    group by earthquake_id
),

origin_count as (
    select earthquake_id,
        count(origin_id) as origin_count
    from {{ ref('int_quakeml_origin') }}
    group by earthquake_id
)

select 
    e.earthquake_id,
    e.event_time_utc,
    to_date(e.event_time_utc) as event_date,
    e.update_time_utc,
    e.longitude,
    e.latitude,
    e.depth_km,
    e.magnitude,
    e.magnitude_type,
    e.significance,
    e.tsunami,
    e.alert,
    ge.flinn_engdahl_region_number,
    e.stations_detected,
    ac.amplitude_count,
    mc.magnitude_count,
    oc.origin_count
from {{ ref('stg_earthquake_events') }} e
left join {{ ref('stg_earthquake_geographic_enrichment') }} ge on e.earthquake_id = ge.earthquake_id
left join amplitude_count ac on e.earthquake_id = ac.earthquake_id
left join magnitude_count mc on e.earthquake_id = mc.earthquake_id
left join origin_count oc on e.earthquake_id = oc.earthquake_id
where event_type = 'earthquake'