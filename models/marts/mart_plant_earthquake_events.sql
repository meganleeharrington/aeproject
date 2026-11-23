with preferred_magnitude as (
    select 
        earthquake_id,
        magnitude_uncertainty,
        evaluation_status as magnitude_evaluation_status
    from {{ ref('fct_earthquake_magnitudes') }}
    where is_preferred_magnitude = true
),

preferred_origin as (
    select
        earthquake_id,
        depth_uncertainty_km,
        horizontal_uncertainty_km,
        evaluation_status as origin_evaluation_status
    from {{ ref('fct_earthquake_origins') }}
    where is_preferred_origin = true
)

select
    p.plant_id,
    p.plant_name,
    e.earthquake_id,
    e.event_time_utc,
    e.event_date, 
    e.magnitude, 
    e.magnitude_type,
    e.magnitude_count,
    pm.magnitude_uncertainty,
    pm.magnitude_evaluation_status,
    e.depth_km,
    p.latitude as plant_latitude, 
    p.longitude as plant_longitude, 
    e.latitude as earthquake_latitude, 
    e.longitude as earthquake_longitude,
    st_distance(
        st_makepoint(p.longitude, p.latitude),
        st_makepoint(e.longitude, e.latitude)
    ) / 1000 as distance_km,
    sr.flinn_engdahl_region_description,
    e.origin_count,
    po.horizontal_uncertainty_km,
    po.depth_uncertainty_km,
    po.origin_evaluation_status
from {{ ref('dim_plant') }} as p

inner join {{ ref('fct_earthquake_events') }} as e
    on st_dwithin(
        st_makepoint(p.longitude, p.latitude),
        st_makepoint(e.longitude, e.latitude),
        50000)
left join preferred_magnitude as pm 
on e.earthquake_id = pm.earthquake_id
left join preferred_origin as po 
on e.earthquake_id = po.earthquake_id
left join {{ ref('dim_seismic_region') }} as sr
on e.flinn_engdahl_region_number = sr.flinn_engdahl_region_number