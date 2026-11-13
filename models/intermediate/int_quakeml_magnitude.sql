select
    earthquake_id,
    get(f.value, '@publicID')::varchar as magnitude_id,
    get(xmlget(xmlget(f.value, 'mag'), 'value'), '$')::float as mag_value,
    get(xmlget(xmlget(f.value, 'mag'), 'uncertainty'), '$')::float as mag_uncertainty,
    get(xmlget(xmlget(f.value, 'mag'), 'confidenceLevel'), '$')::float as mag_confidence_level,
    get(xmlget(f.value, 'type'), '$')::varchar as type,
    get(xmlget(f.value, 'originID'), '$')::varchar as origin_id,
    get(xmlget(f.value, 'methodID'), '$')::varchar as method_id,
    get(xmlget(f.value, 'stationCount'), '$')::int as station_count,
    get(xmlget(f.value, 'evaluationMode'), '$')::varchar as evaluation_mode,
    get(xmlget(f.value, 'evaluationStatus'), '$')::varchar as evaluation_status,
    get(xmlget(xmlget(f.value, 'creationInfo'), 'agencyID'), '$')::varchar as agency_id,
    get(xmlget(xmlget(f.value, 'creationInfo'), 'agencyURI'), '$')::varchar as agency_uri,
    try_to_timestamp_tz(get(xmlget(xmlget(f.value, 'creationInfo'), 'creationTime'), '$')::varchar) as creation_time
from {{ ref('int_quakeml_parsed') }},
lateral flatten (
    input => get(xmlget(xmlget(parsed_xml, 'eventParameters'), 'event'), '$')
) f
where get(f.value, '@')::varchar = 'magnitude'