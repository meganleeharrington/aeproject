select
    c.earthquake_id,
    c.magnitude_id
from {{ ref('int_quakeml_station_magnitude_contribution') }} c
left join {{ ref('int_quakeml_magnitude') }} m
    on c.earthquake_id = m.earthquake_id
    and c.magnitude_id = m.magnitude_id
where m.magnitude_id is null