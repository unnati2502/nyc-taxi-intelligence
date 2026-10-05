CREATE OR REPLACE VIEW vw_trip_analysis AS

SELECT

    f.trip_id,

    f.pickup_datetime,
    f.dropoff_datetime,

    f.pickup_date,
    f.pickup_hour,
    f.pickup_weekday_num,

    f.is_weekend,
    f.is_rush_hour,

    pz.borough AS pickup_borough,
    pz.zone AS pickup_zone,

    dz.borough AS dropoff_borough,
    dz.zone AS dropoff_zone,

    p.payment_method,

    f.passenger_count,

    f.trip_distance,
    f.trip_duration_minutes,
    f.avg_speed_mph,

    f.fare_amount,
    f.tip_amount,
    f.tolls_amount,
    f.total_amount,

    f.congestion_surcharge,
    f.airport_fee,
    f.cbd_congestion_fee,

    f.revenue_per_mile,
    f.revenue_per_minute,

    f.tip_percentage,

    f.valid_tip_analysis,
    f.valid_revenue_efficiency

FROM fact_trips f

LEFT JOIN dim_zone pz
    ON f.pickup_location_id
       = pz.location_id

LEFT JOIN dim_zone dz
    ON f.dropoff_location_id
       = dz.location_id

LEFT JOIN dim_payment p
    ON f.payment_type
       = p.payment_type;




-- ============================================================
-- HOURLY ZONE ANALYTICS
-- Optimized for Tableau and forecasting
-- ============================================================

DROP MATERIALIZED VIEW IF EXISTS mv_hourly_zone_metrics;

CREATE MATERIALIZED VIEW mv_hourly_zone_metrics AS

SELECT

    f.pickup_date,

    f.pickup_hour,

    f.pickup_location_id,

    z.borough,
    z.zone,

    f.is_weekend,
    f.is_rush_hour,

    COUNT(*) AS trip_count,

    ROUND(
        SUM(f.total_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(f.total_amount),
        2
    ) AS avg_revenue_per_trip,

    ROUND(
        AVG(f.trip_distance),
        2
    ) AS avg_trip_distance,

    ROUND(
        AVG(f.trip_duration_minutes),
        2
    ) AS avg_trip_duration,

    ROUND(
        AVG(f.avg_speed_mph),
        2
    ) AS avg_speed

FROM fact_trips f

JOIN dim_zone z
    ON f.pickup_location_id
       = z.location_id

GROUP BY

    f.pickup_date,
    f.pickup_hour,
    f.pickup_location_id,

    z.borough,
    z.zone,

    f.is_weekend,
    f.is_rush_hour;


CREATE OR REPLACE VIEW vw_daily_kpis AS

SELECT

    pickup_date,

    COUNT(*) AS total_trips,

    ROUND(
        SUM(total_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(total_amount),
        2
    ) AS avg_revenue_per_trip,

    ROUND(
        AVG(trip_distance),
        2
    ) AS avg_trip_distance,

    ROUND(
        AVG(trip_duration_minutes),
        2
    ) AS avg_trip_duration,

    ROUND(
        AVG(avg_speed_mph),
        2
    ) AS avg_speed

FROM fact_trips

GROUP BY pickup_date;