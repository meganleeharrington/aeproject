select
    plant_code,
    generator_id,
    technology,
    prime_mover,
    status,
    nameplate_capacity_mw,
    summer_capacity_mw,
    winter_capacity_mw,
    operating_month,
    operating_year,
    energy_source_1
from {{ ref('eia_generators_2025') }}