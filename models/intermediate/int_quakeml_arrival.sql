select 
    earthquake_id,
    get(o.value, '@publicID')::varchar as origin_id,
    get(a.value, '@publicID')::varchar as arrival_id,
    get(xmlget(a.value, 'pickID'), '$')::varchar as pick_id,
    get(xmlget(a.value, 'phase'), '$')::varchar as phase,
    get(xmlget(a.value, 'azimuth'), '$')::varchar as azimuth,
    get(xmlget(a.value, 'distance'), '$')::float as distance,
    get(xmlget(a.value, 'timeResidual'), '$')::float as time_residual,
    get(xmlget(a.value, 'timeWeight'), '$')::float as time_weight,
    get(xmlget(xmlget(a.value, 'creationInfo'), 'agencyID'), '$')::varchar as agency_id,
    get(xmlget(xmlget(a.value, 'creationInfo'), 'agencyURI'), '$')::varchar as agency_uri,
    get(xmlget(xmlget(a.value, 'creationInfo'), 'author'), '$')::varchar as author,
    try_to_timestamp_tz(get(xmlget(xmlget(a.value, 'creationInfo'), 'creationTime'), '$')::varchar) as creation_time
from int_quakeml_parsed,
lateral flatten (
    input => get(xmlget(xmlget(parsed_xml, 'eventParameters'), 'event'), '$')
) o,
lateral flatten (
    input => get(o.value, '$')
) a
where get(o.value, '@')::varchar = 'origin'
    and get(a.value, '@')::varchar = 'arrival'