select
    p.plant_id,
    e.earthquake_id,
    st_distance(
        st_makepoint(p.longitude, p.latitude),
        st_makepoint(e.longitude, e.latitude)
    ) / 1000 as distance_km
from {{ ref('dim_plant') }} p
cross join {{ ref('fct_earthquake_events') }} e
where st_dwithin(
    st_makepoint(p.longitude, p.latitude),
    st_makepoint(e.longitude, e.latitude),
    50000
)