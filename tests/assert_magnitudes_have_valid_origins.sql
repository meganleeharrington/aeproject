select 
    m.earthquake_id,
    m.origin_id
from {{ ref('int_quakeml_magnitude') }} m
left join {{ ref('int_quakeml_origin') }} o
on m.earthquake_id = o.earthquake_id and m.origin_id = o.origin_id
where o.origin_id is null and m.origin_id is not null