DROP MATERIALIZED VIEW IF EXISTS mv_hourly_zone_demand;

CREATE MATERIALIZED VIEW mv_hourly_zone_demand AS

SELECT
    f.pickup_date,
    f.pickup_hour,
    f.pickup_location_id,

    z.borough,
    z.zone,

    COUNT(*) AS trip_count,

    ROUND(
        AVG(f.total_amount),
        2
    ) AS avg_trip_revenue,

    ROUND(
        AVG(f.trip_duration_minutes),
        2
    ) AS avg_trip_duration

FROM fact_trips f

JOIN dim_zone z
    ON f.pickup_location_id = z.location_id

WHERE z.borough <> 'Unknown'

GROUP BY
    f.pickup_date,
    f.pickup_hour,
    f.pickup_location_id,
    z.borough,
    z.zone;