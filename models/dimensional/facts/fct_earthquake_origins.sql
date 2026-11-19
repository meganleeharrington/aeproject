select
    o.earthquake_id,
    o.origin_id,
    o.origin_time as origin_time_utc,
    o.latitude,
    o.longitude,
    o.depth / 1000 as depth_km,
    o.horizontal_uncertainty / 1000 as horizontal_uncertainty_km,
    o.standard_error,
    o.depth_uncertainty / 1000 as depth_uncertainty_km,
    o.azimuthal_gap,
    o.used_phase_count,
    o.used_station_count,
    o.evaluation_mode,
    o.evaluation_status,
    case
        when e.preferred_origin_id is null then null
        when e.preferred_origin_id = o.origin_id then true
        else false 
    end as is_preferred_origin,
    o.associated_station_count
from {{ ref('int_quakeml_origin') }} o
left join {{ ref('int_quakeml_event') }} e
    on o.earthquake_id = e.earthquake_id