select
    p.plant_code as plant_id,
    p.plant_name,
    p.utility_id,
    p.utility_name,
    p.city,
    p.state,
    p.zip,
    p.county,
    p.latitude,
    p.longitude,
    count(distinct g.generator_id) as generator_count,
    count(distinct case when status = 'OP' then generator_id end) as operating_generator_count,
    count(distinct case when status = 'OS' then generator_id end) as permanently_out_of_service_generator_count,
    count(distinct case when status = 'SB' then generator_id end) as standby_generator_count,
    count(distinct case when g.status = 'OA' then g.generator_id end) as temporarily_out_of_service_generator_count,
    sum(nameplate_capacity_mw) as total_nameplate_capacity_mw,    
    sum(summer_capacity_mw) as total_summer_capacity_mw,
    sum(winter_capacity_mw) as total_winter_capacity_mw
from {{ ref('stg_eia_plants') }} p
inner join {{ ref('stg_eia_generators') }} g
    on p.plant_code = g.plant_code
where g.technology = 'Geothermal'
group by all