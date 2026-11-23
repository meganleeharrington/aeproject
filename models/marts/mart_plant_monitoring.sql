with reporting_dates as (
    {{dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2026-01-01' as date)",
            end_date="current_date()")
    }}
),

plant_dates as (
    select
        p.plant_id,
        d.date_day as reporting_date
    from {{ ref('dim_plant') }} as p
    cross join reporting_dates as d
)

select
    pd.plant_id,
    pd.reporting_date,
    coalesce(count_if(e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date), 0) as earthquake_count_7d,
    count(e.earthquake_id) as earthquake_count_30d,
    max(case when e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date then e.magnitude end) as max_magnitude_7d,
    avg(case when e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date then e.magnitude end) as avg_magnitude_7d,
    max(case when e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date then e.depth_km end) as max_depth_km_7d,
    avg(case when e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date then e.depth_km end) as avg_depth_km_7d,
    avg(case when e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date then e.distance_km end) as avg_distance_km_7d,
    min(case when e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date then e.distance_km end) as min_distance_km_7d,
    coalesce(count_if(e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date and e.distance_km <= 10), 0) as earthquake_count_within_10km_7d,
    coalesce(count_if(e.event_date between dateadd(day, -6, pd.reporting_date) and pd.reporting_date and e.distance_km > 10 and e.distance_km <= 25), 0) as earthquake_count_10km_to_25km_7d,
    max(e.event_time_utc) as most_recent_earthquake_30d
from plant_dates as pd
left join {{ ref('mart_plant_earthquake_events') }} as e
on pd.plant_id = e.plant_id and e.event_date between dateadd(day, -29, pd.reporting_date) and pd.reporting_date
group by pd.plant_id, pd.reporting_date