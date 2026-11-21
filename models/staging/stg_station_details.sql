select network,
    station,
    latitude,
    longitude,
    elevation,
    sitename,
    try_to_date(starttime) as latest_start_time,
    try_to_date(endtime) as latest_end_time
from {{ ref('station_details') }}
qualify row_number() over (
    partition by network, station
    order by latest_end_time DESC NULLS FIRST, latest_start_time DESC) = 1