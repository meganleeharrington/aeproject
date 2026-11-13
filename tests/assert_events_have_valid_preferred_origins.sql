select 
    e.earthquake_id,
    e.preferred_origin_id
from {{ ref('int_quakeml_event') }} e
left join {{ ref('int_quakeml_origin') }} o
on e.earthquake_id = o.earthquake_id and e.preferred_origin_id = o.origin_id
where o.origin_id is null and e.preferred_origin_id is not null