select distinct
    earthquake_id,
    get(f.value, '@publicID')::varchar as amplitude_id,
    get(xmlget(xmlget(f.value,'genericAmplitude'), 'value'), '$')::float as generic_amplitude,
    get(xmlget(f.value, 'type'), '$')::varchar as amplitude_type,
    get(xmlget(f.value, 'unit'), '$')::varchar as unit,
    get(xmlget(xmlget(f.value, 'period'), 'value'), '$')::float as period,
    get(xmlget(xmlget(f.value, 'timeWindow'), 'begin'), '$')::float as time_window_begin,
    get(xmlget(xmlget(f.value, 'timeWindow'), 'end'), '$')::float as time_window_end,
    get(xmlget(xmlget(f.value, 'timeWindow'), 'reference'), '$')::varchar as time_window_reference,
    get(xmlget(f.value, 'pickID'), '$')::varchar as pick_id,
    get(xmlget(f.value, 'waveformID'), '@channelCode')::varchar as channel_code,
    get(xmlget(f.value, 'waveformID'), '@stationCode')::varchar as station_code,
    get(xmlget(f.value, 'waveformID'), '@networkCode')::varchar as network_code,
    get(xmlget(f.value, 'waveformID'), '@locationCode')::varchar AS location_code,
    try_to_timestamp_tz(get(xmlget(xmlget(f.value, 'scalingTime'), 'value'), '$')::varchar) as scaling_time,
    get(xmlget(f.value, 'magnitudeHint'), '$')::varchar as magnitude_hint,
    get(xmlget(f.value, 'evaluationMode'), '$')::varchar as evaluation_mode
from {{ref('int_quakeml_parsed')}},
lateral flatten(input => get(xmlget(xmlget(parsed_xml, 'eventParameters'),'event'),'$')) as f
where get(f.value, '@')::varchar = 'amplitude';