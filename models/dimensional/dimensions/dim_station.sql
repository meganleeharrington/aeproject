with stations as (
    select
        network_code,
        station_code
    from int_quakeml_amplitude

    union

    select
        network_code,
        station_code
    from int_quakeml_pick
),

details as (
    select         
        network,
        station,
        latitude,
        longitude,
        elevation,
        latest_start_time,
        latest_end_time
    from stg_station_details
)

select
    {{ dbt_utils.generate_surrogate_key([
        'network_code',
        'station_code'
    ]) }} AS station_key,
    network_code,
    station_code,
    latitude,
    longitude,
    elevation,
    latest_start_time,
    latest_end_time
from stations as s
left join stg_station_details as sd
on s.network_code = sd.network and s.station_code = sd.station
where network_code is not null 
and station_code is not null