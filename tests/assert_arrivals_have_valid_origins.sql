select 
    a.earthquake_id, 
    a.arrival_id,
    a.origin_id
from {{ ref('int_quakeml_arrival') }} a
left join {{ ref('int_quakeml_origin') }} o
on a.earthquake_id = o.earthquake_id
and a.origin_id = o.origin_id
where o.origin_id is null