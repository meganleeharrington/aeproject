select 
    earthquake_id,
    max(case when get(c.value, '@')::varchar = 'description' and get(xmlget(c.value, 'type'), '$')::varchar = 'Flinn-Engdahl region'
        then get(xmlget(c.value, 'text'), '$')::varchar end) as flinn_engdahl_region_description,
    get(xmlget(f.value, 'preferredMagnitudeID'), '$')::varchar as preferred_magnitude_id,
    get(xmlget(f.value, 'preferredOriginID'), '$')::varchar as preferred_origin_id,
    get(xmlget(f.value, 'type'), '$')::varchar as event_type,
    get(xmlget(xmlget(f.value, 'creationInfo'), 'agencyID'), '$')::varchar as agency_id,
    get(xmlget(xmlget(f.value, 'creationInfo'), 'agencyURI'), '$')::varchar as agency_uri,
    try_to_timestamp_tz(get(xmlget(xmlget(f.value, 'creationInfo'), 'creationTime'), '$')::varchar) as creation_time
from {{ ref('int_quakeml_parsed') }},
lateral flatten (
    input => get(xmlget(parsed_xml, 'eventParameters'), '$')
) f,
lateral flatten (
        input => get(f.value, '$')
    ) c
where get(f.value, '@')::varchar = 'event'
group by all;