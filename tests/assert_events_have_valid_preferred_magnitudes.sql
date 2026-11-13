select 
    e.earthquake_id,
    e.preferred_magnitude_id
from {{ ref('int_quakeml_event') }} e
left join {{ ref('int_quakeml_magnitude') }} m
on e.earthquake_id = m.earthquake_id and e.preferred_magnitude_id = m.magnitude_id
where m.magnitude_id is null and e.preferred_magnitude_id is not null