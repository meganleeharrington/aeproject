select 
    earthquake_id,
    get(f.value, '@publicID')::varchar as origin_id,
    
    --originUncertainty
    get(xmlget(xmlget(f.value, 'originUncertainty'), 'horizontalUncertainty'), '$')::float as horizontal_uncertainty,
    get(xmlget(xmlget(f.value, 'originUncertainty'), 'minHorizontalUncertainty'), '$')::float as min_horizontal_uncertainty,
    get(xmlget(xmlget(f.value, 'originUncertainty'), 'maxHorizontalUncertainty'), '$')::float as max_horizontal_uncertainty,
    get(xmlget(xmlget(f.value, 'originUncertainty'), 'azimuthMaxHorizontalUncertainty'), '$')::float as azimuth_max_horizontal_uncertainty,
    get(xmlget(xmlget(xmlget(f.value, 'originUncertainty'), 'confidenceEllipsoid'), 'semiMajorAxisLength'), '$')::float as semi_major_axis_length,
    get(xmlget(xmlget(xmlget(f.value, 'originUncertainty'), 'confidenceEllipsoid'), 'semiMinorAxisLength'), '$')::float as semi_minor_axis_length,
    get(xmlget(xmlget(xmlget(f.value, 'originUncertainty'), 'confidenceEllipsoid'), 'semiIntermediateAxisLength'), '$')::float as semi_intermediate_axis_length,
    get(xmlget(xmlget(xmlget(f.value, 'originUncertainty'), 'confidenceEllipsoid'), 'majorAxisPlunge'), '$')::float as major_axis_plunge,
    get(xmlget(xmlget(xmlget(f.value, 'originUncertainty'), 'confidenceEllipsoid'), 'majorAxisAzimuth'), '$')::float as major_axis_azimuth,
    get(xmlget(xmlget(xmlget(f.value, 'originUncertainty'), 'confidenceEllipsoid'), 'majorAxisRotation'), '$')::float as major_axis_rotation,
    get(xmlget(xmlget(f.value, 'originUncertainty'), 'preferredDescription'), '$')::varchar as preferred_description,
    get(xmlget(xmlget(f.value, 'originUncertainty'), 'confidenceLevel'), '$')::float as confidence_level,

    --Time
    try_to_timestamp_tz(get(xmlget(xmlget(f.value, 'time'), 'value'), '$')::varchar) as origin_time,
    get(xmlget(xmlget(f.value, 'time'), 'uncertainty'), '$')::float as time_uncertainty,
    get(xmlget(xmlget(f.value, 'time'), 'confidenceLevel') , '$')::float as time_confidence_level,

    --Longitude
    get(xmlget(xmlget(f.value, 'longitude'), 'value'), '$')::float as longitude,
    get(xmlget(xmlget(f.value, 'longitude'), 'uncertainty'), '$')::float as longitude_uncertainty,
    get(xmlget(xmlget(f.value, 'longitude'), 'confidenceLevel'), '$')::float as longitude_confidence_level,

    --Latitude
    get(xmlget(xmlget(f.value, 'latitude'), 'value'), '$')::float as latitude,
    get(xmlget(xmlget(f.value, 'latitude'), 'uncertainty'), '$')::float as latitude_uncertainty,
    get(xmlget(xmlget(f.value, 'latitude'), 'confidenceLevel'), '$')::float as latitude_confidence_level,

    --Depth
    get(xmlget(xmlget(f.value, 'depth'), 'value'), '$')::float as depth,
    get(xmlget(xmlget(f.value, 'depth'), 'uncertainty'), '$')::float as depth_uncertainty,
    get(xmlget(xmlget(f.value, 'depth'), 'confidenceLevel'), '$')::float as depth_confidence_level,

    --Other
    get(xmlget(f.value, 'depthType'), '$')::varchar as depth_type,
    get(xmlget(f.value, 'methodID'), '$')::varchar as method_id,
    get(xmlget(f.value, 'earthModelID'), '$')::varchar as earth_model_id,
    get(xmlget(f.value, 'type'), '$')::varchar as type,
    get(xmlget(f.value, 'evaluationMode'), '$')::varchar as evaluation_mode,
    get(xmlget(f.value, 'evaluationStatus'), '$')::varchar as evaluation_status,

    --Quality
    get(xmlget(xmlget(f.value, 'quality'), 'associatedPhaseCount'), '$')::int as associated_phase_count,
    get(xmlget(xmlget(f.value, 'quality'), 'usedPhaseCount'), '$')::int as used_phase_count,
    get(xmlget(xmlget(f.value, 'quality'), 'associatedStationCount'), '$')::int as associated_station_count,
    get(xmlget(xmlget(f.value, 'quality'), 'usedStationCount'), '$')::int as used_station_count,
    get(xmlget(xmlget(f.value, 'quality'), 'standardError'), '$')::float as standard_error,
    get(xmlget(xmlget(f.value, 'quality'), 'azimuthalGap'), '$')::float as azimuthal_gap,
    get(xmlget(xmlget(f.value, 'quality'), 'secondaryAzimuthalGap'), '$')::float as secondary_azimuthal_gap,
    get(xmlget(xmlget(f.value, 'quality'), 'minimumDistance'), '$')::float as minimum_distance
    
from {{ref('int_quakeml_parsed')}},
lateral flatten (
    input => get(xmlget(xmlget(parsed_xml, 'eventParameters'), 'event'), '$')
) f
where get(f.value, '@')::varchar = 'origin'