select 
    sm.earthquake_id,
    sm.origin_id
from {{ ref('int_quakeml_station_magnitudes') }} sm
left join {{ ref('int_quakeml_origin') }} o
on sm.earthquake_id = o.earthquake_id and sm.origin_id = o.origin_id
where o.origin_id is null and sm.origin_id is not null