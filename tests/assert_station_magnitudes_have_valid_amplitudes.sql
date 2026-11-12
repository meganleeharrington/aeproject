{{ config(severity='warn') }}

select 
    sm.earthquake_id
    ,sm.amplitude_id
from {{ ref('int_station_magnitudes') }} as sm
left join {{ ref('int_quakeml_amplitude') }} as a
    on sm.earthquake_id = a.earthquake_id
    and sm.amplitude_id = a.amplitude_id
where sm.amplitude_id is not null
    and a.amplitude_id is null