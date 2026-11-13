with t as (
    select 
        earthquake_id,
        split(max(case when get(xmlget(c.value, 'type'), '$')::varchar = 'nearest cities'
        then get(xmlget(c.value, 'text'), '$')::varchar end), chr(10) || chr(10)) as nearest_cities_description,
    from {{ ref('int_quakeml_parsed') }},
    lateral flatten (
        input => get(xmlget(parsed_xml, 'eventParameters'), '$')
    ) f,
    lateral flatten (
        input => get(f.value, '$')
    ) c
    where get(f.value, '@')::varchar = 'event' and get(c.value, '@')::varchar = 'description'
    group by all
)

select 
    earthquake_id,
    f.index as city_rank,
    regexp_substr(f.value::varchar, 'of ([^,]+),', 1, 1, 'e', 1)::varchar as city,
    regexp_substr(f.value::varchar, ', ([^,]+),', 1, 1, 'e', 1)::varchar as state_or_province,
    regexp_substr(f.value::varchar, ', ([^,]+) [(]pop', 1, 1, 'e', 1)::varchar as country,
    regexp_substr(f.value::varchar, '^([0-9]+([.][0-9]+)?) km', 1, 1, 'e', 1)::float as distance_km,
    regexp_substr(f.value::varchar, '[)] ([A-Z]+) of', 1, 1, 'e', 1)::varchar as direction,
    regexp_substr(f.value::varchar, 'pop[.] ([0-9]+)', 1, 1, 'e', 1)::int as population
from t,
lateral flatten (
    input => nearest_cities_description
) f
order by earthquake_id, city_rank;