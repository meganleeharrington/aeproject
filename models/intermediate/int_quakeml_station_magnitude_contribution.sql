select
    earthquake_id,
    get(f.value, '@publicID')::varchar as magnitude_id,
    get(xmlget(c.value, 'stationMagnitudeID'), '$')::varchar as station_magnitude_id,
    get(xmlget(c.value, 'weight'), '$')::float as weight
from {{ ref('int_quakeml_parsed') }},
lateral flatten (
    input => get(xmlget(xmlget(parsed_xml, 'eventParameters'), 'event'), '$')
) f,
lateral flatten (
    input => get(f.value, '$')
) c
where get(f.value, '@')::varchar = 'magnitude'
  and get(c.value, '@')::varchar = 'stationMagnitudeContribution'