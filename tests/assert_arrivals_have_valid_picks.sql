select 
    a.earthquake_id,
    a.arrival_id,
    a.pick_id
from {{ ref('int_quakeml_arrival') }} a
left join {{ ref('int_quakeml_pick') }} p
    on a.earthquake_id = p.earthquake_id
    and a.pick_id = p.pick_id
where p.pick_id is null