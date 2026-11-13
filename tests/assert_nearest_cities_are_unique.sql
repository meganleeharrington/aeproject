{{ config(severity='warn') }}

select 
    earthquake_id,
    city,
    state_or_province,
    country,
    count(*)
from {{ ref('int_quakeml_nearest_cities') }}
group by all
having count(*) > 1;