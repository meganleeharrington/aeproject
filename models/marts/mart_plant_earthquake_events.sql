select
    p.plant_id,
    p.plant_name,
    e.earthquake_id,
    e.event_time_utc,
    e.event_date, 
    e.magnitude, 
    e.magnitude_type, 
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
from {{ ref('dim_plant') }} as p

inner join {{ ref('fct_earthquake_events') }} as e
    on st_dwithin(
        st_makepoint(p.longitude, p.latitude),
        st_makepoint(e.longitude, e.latitude),
        50000)

left join {{ ref('dim_seismic_region') }} sr
on e.flinn_engdahl_region_number = sr.flinn_engdahl_region_number;