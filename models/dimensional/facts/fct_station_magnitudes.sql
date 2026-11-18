select
    sm.earthquake_id,
    sm.station_magnitude_id,
    sm.origin_id,
    ds.station_key,
    sm.amplitude_id,
    sm.magnitude,
    sm.magnitude_type
from {{ ref('int_quakeml_station_magnitudes') }} sm
left join {{ ref('int_quakeml_amplitude') }} a
    on sm.earthquake_id = a.earthquake_id
    and sm.amplitude_id = a.amplitude_id
left join {{ ref('dim_station') }} ds
    on a.network_code = ds.network_code
    and a.station_code = ds.station_code