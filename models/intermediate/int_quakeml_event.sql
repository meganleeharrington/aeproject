select 
    earthquake_id,
    get(xmlget(f.value, 'preferredMagnitudeID'), '$')::varchar as preferred_magnitude_id,
    get(xmlget(f.value, 'preferredOriginID'), '$')::varchar as preferred_origin_id,
    get(xmlget(f.value, 'type'), '$')::varchar as event_type,
    get(xmlget(xmlget(f.value, 'creationInfo'), 'agencyID'), '$')::varchar as agency_id,
    get(xmlget(xmlget(f.value, 'creationInfo'), 'agencyURI'), '$')::varchar as agency_uri,
    try_to_timestamp_tz(get(xmlget(xmlget(f.value, 'creationInfo'), 'creationTime'), '$')::varchar) as creation_time
from {{ ref('int_quakeml_parsed') }},
lateral flatten (
    input => get(xmlget(parsed_xml, 'eventParameters'), '$')
) f
where get(f.value, '@')::varchar = 'event';