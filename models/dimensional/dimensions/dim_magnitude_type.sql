
with all_magnitudes as (
    
    select distinct magnitude_type as type
    from INT_QUAKEML_STATION_MAGNITUDES

    union

    select distinct type
    from INT_QUAKEML_MAGNITUDE
)

select 
    am.type,
    shape,
    range,
    distance_range,
    equation,
    comments
from all_magnitudes as am
left join {{ ref('magnitude_type') }} as mt
on am.type = mt.type