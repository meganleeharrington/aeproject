select
    m.earthquake_id,
    m.magnitude_id,
    m.origin_id,
    m.mag_value as magnitude,
    m.type as magnitude_type,
    m.mag_uncertainty as magnitude_uncertainty,
    m.mag_confidence_level as magnitude_confidence_level,
    m.station_count,
    m.evaluation_mode,
    m.evaluation_status,
    m.agency_id,
    m.creation_time as creation_time_utc,
    case
        when e.preferred_magnitude_id is null then null
        when e.preferred_magnitude_id = m.magnitude_id then true
        else false
    end as is_preferred_magnitude
from {{ ref('int_quakeml_magnitude') }} m
left join {{ ref('int_quakeml_event') }} e
    on m.earthquake_id = e.earthquake_id