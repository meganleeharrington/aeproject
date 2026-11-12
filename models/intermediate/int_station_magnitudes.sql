with events as (
    select
        earthquake_id,
        xmlget(xmlget(parsed_xml, 'eventParameters'),'event') as event_xml
    from {{ ref('int_quakeml_parsed') }}
),

station_magnitudes as (
    select 
        earthquake_id,
        f.value AS station_xml
    from events,
    lateral flatten(input => get(event_xml, '$')) f
    where get(f.value, '@')::varchar = 'stationMagnitude'
)

select
    earthquake_id,
    get(station_xml, '@publicID')::varchar as station_magnitude_id,
    get(xmlget(station_xml, 'originID'), '$')::varchar as origin_id,
    get(xmlget(xmlget(station_xml, 'mag'), 'value'),'$')::float as magnitude,
    get(xmlget(station_xml, 'type'), '$')::varchar as magnitude_type,
    get(xmlget(station_xml, 'amplitudeID'), '$')::varchar as amplitude_id
from station_magnitudes