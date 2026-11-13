select
    c.earthquake_id,
    c.station_magnitude_id
from {{ ref('int_quakeml_station_magnitude_contribution') }} c
left join {{ ref('int_quakeml_station_magnitudes') }} m
    on c.earthquake_id = m.earthquake_id
    and c.station_magnitude_id = m.station_magnitude_id
where m.station_magnitude_id is null