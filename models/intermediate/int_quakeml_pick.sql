select 
    earthquake_id,
    get(f.value, '@publicID')::varchar as amplitude_id,
    try_to_timestamp_tz(get(xmlget(xmlget(f.value, 'time'), 'value'), '$')::varchar) as time,
    get(xmlget(f.value, 'waveformID'), '@channelCode')::varchar as channel_code,
    get(xmlget(f.value, 'waveformID'), '@locationCode')::varchar as location_code,
    get(xmlget(f.value, 'waveformID'), '@networkCode')::varchar as network_code,
    get(xmlget(f.value, 'waveformID'), '@stationCode')::varchar as station_code,
    get(xmlget(f.value, 'phaseHint'), '$')::varchar as phase_hint,
    get(xmlget(f.value, 'evaluationMode'), '$')::varchar as evaluation_mode,
    get(xmlget(xmlget(f.value, 'creationInfo'), 'agencyID'), '$')::varchar as agency_id,
    try_to_timestamp_tz(get(xmlget(xmlget(f.value, 'creationInfo'), 'creationTime'), '$')::varchar) as creation_time,
from {{ref('int_quakeml_parsed')}},
lateral flatten (input => get(xmlget(xmlget(parsed_xml, 'eventParameters'), 'event'), '$')) as f
where get(f.value, '@')::varchar = 'pick'