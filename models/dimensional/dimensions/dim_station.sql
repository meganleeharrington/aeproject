select {{ dbt_utils.generate_surrogate_key(['network_code', 'station_code']) }} as station_key,
    network_code,
    station_code
from {{ ref('int_quakeml_amplitude') }}
group by all