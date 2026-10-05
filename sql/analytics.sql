-- ============================================================
-- NYC TAXI DEMAND & REVENUE INTELLIGENCE
-- Advanced SQL Business Analysis
-- Analysis Period: January - June 2025
-- ============================================================


-- ============================================================
-- 1. EXECUTIVE KPIs
-- ============================================================

SELECT
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
    ) AS avg_trip_duration_minutes,

    ROUND(
        AVG(avg_speed_mph),
        2
    ) AS avg_speed_mph

FROM fact_trips;


-- ============================================================
-- 2. MONTHLY DEMAND TREND
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        pickup_datetime
    )::DATE AS month,

    COUNT(*) AS total_trips,

    ROUND(
        SUM(total_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(total_amount),
        2
    ) AS avg_revenue_per_trip

FROM fact_trips

GROUP BY 1

ORDER BY 1;

-- ============================================================
-- 3. MONTH-OVER-MONTH DEMAND GROWTH
-- ============================================================

WITH monthly_trips AS (

    SELECT
        DATE_TRUNC(
            'month',
            pickup_datetime
        )::DATE AS month,

        COUNT(*) AS trips

    FROM fact_trips

    GROUP BY 1
),

growth AS (

    SELECT
        month,
        trips,

        LAG(trips)
        OVER (
            ORDER BY month
        ) AS previous_month_trips

    FROM monthly_trips
)

SELECT
    month,
    trips,
    previous_month_trips,

    ROUND(
        100.0
        * (trips - previous_month_trips)
        / NULLIF(previous_month_trips, 0),
        2
    ) AS mom_growth_pct

FROM growth

ORDER BY month;

-- ============================================================
-- 4. HOURLY DEMAND
-- ============================================================

SELECT
    pickup_hour,

    COUNT(*) AS total_trips,

    ROUND(
        AVG(total_amount),
        2
    ) AS avg_revenue_per_trip,

    ROUND(
        AVG(trip_duration_minutes),
        2
    ) AS avg_trip_duration

FROM fact_trips

GROUP BY pickup_hour

ORDER BY pickup_hour;


-- ============================================================
-- 5. WEEKDAY × HOUR DEMAND
-- ============================================================

SELECT
    pickup_weekday_num,
    pickup_hour,
    COUNT(*) AS trips

FROM fact_trips

GROUP BY
    pickup_weekday_num,
    pickup_hour

ORDER BY
    pickup_weekday_num,
    pickup_hour;


-- ============================================================
-- 6. RUSH HOUR PERFORMANCE
-- ============================================================

SELECT

    CASE
        WHEN is_rush_hour
            THEN 'Rush Hour'
        ELSE 'Non-Rush Hour'
    END AS period,

    COUNT(*) AS trips,

    ROUND(
        AVG(trip_duration_minutes),
        2
    ) AS avg_duration,

    ROUND(
        AVG(avg_speed_mph),
        2
    ) AS avg_speed,

    ROUND(
        AVG(total_amount),
        2
    ) AS avg_revenue,

    ROUND(
        AVG(revenue_per_minute)
            FILTER (
                WHERE valid_revenue_efficiency
            ),
        2
    ) AS avg_revenue_per_minute

FROM fact_trips

GROUP BY is_rush_hour

ORDER BY trips DESC;

-- ============================================================
-- 7. TOP PICKUP ZONES BY DEMAND
-- ============================================================

SELECT

    z.borough,
    z.zone,

    COUNT(*) AS trips,

    ROUND(
        SUM(f.total_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(f.total_amount),
        2
    ) AS avg_revenue_per_trip

FROM fact_trips f

JOIN dim_zone z
    ON f.pickup_location_id
       = z.location_id

WHERE z.borough <> 'Unknown'

GROUP BY
    z.borough,
    z.zone

ORDER BY trips DESC

LIMIT 20;

-- ============================================================
-- 8. TOP PICKUP ZONES BY REVENUE
-- ============================================================

SELECT

    z.borough,
    z.zone,

    COUNT(*) AS trips,

    ROUND(
        SUM(f.total_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(f.total_amount),
        2
    ) AS avg_revenue_per_trip

FROM fact_trips f

JOIN dim_zone z
    ON f.pickup_location_id
       = z.location_id

WHERE z.borough <> 'Unknown'

GROUP BY
    z.borough,
    z.zone

HAVING COUNT(*) >= 1000

ORDER BY total_revenue DESC

LIMIT 20;


-- ============================================================
-- 9. ZONE REVENUE EFFICIENCY
-- ============================================================

SELECT

    z.borough,
    z.zone,

    COUNT(*) AS trips,

    ROUND(
        AVG(f.revenue_per_mile)
        FILTER (
            WHERE f.valid_revenue_efficiency
        ),
        2
    ) AS avg_revenue_per_mile,

    ROUND(
        AVG(f.revenue_per_minute)
        FILTER (
            WHERE f.valid_revenue_efficiency
        ),
        2
    ) AS avg_revenue_per_minute

FROM fact_trips f

JOIN dim_zone z
    ON f.pickup_location_id
       = z.location_id

WHERE z.borough <> 'Unknown'

GROUP BY
    z.borough,
    z.zone

HAVING COUNT(*) >= 5000

ORDER BY avg_revenue_per_minute DESC

LIMIT 20;

-- ============================================================
-- 10. BOROUGH PERFORMANCE
-- ============================================================

SELECT

    z.borough,

    COUNT(*) AS trips,

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

WHERE z.borough NOT IN (
    'Unknown',
    'EWR'
)

GROUP BY z.borough

ORDER BY trips DESC;

-- ============================================================
-- 11. MOST POPULAR ROUTES
-- ============================================================

SELECT

    pz.zone AS pickup_zone,
    dz.zone AS dropoff_zone,

    COUNT(*) AS trips,

    ROUND(
        AVG(f.trip_distance),
        2
    ) AS avg_distance,

    ROUND(
        AVG(f.trip_duration_minutes),
        2
    ) AS avg_duration,

    ROUND(
        AVG(f.total_amount),
        2
    ) AS avg_revenue

FROM fact_trips f

JOIN dim_zone pz
    ON f.pickup_location_id
       = pz.location_id

JOIN dim_zone dz
    ON f.dropoff_location_id
       = dz.location_id

WHERE
    pz.borough <> 'Unknown'
    AND dz.borough <> 'Unknown'

GROUP BY
    pz.zone,
    dz.zone

HAVING COUNT(*) >= 1000

ORDER BY trips DESC

LIMIT 25;

-- ============================================================
-- 12. HIGHEST-VALUE ROUTES
-- ============================================================

SELECT

    pz.zone AS pickup_zone,
    dz.zone AS dropoff_zone,

    COUNT(*) AS trips,

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
    ) AS avg_distance

FROM fact_trips f

JOIN dim_zone pz
    ON f.pickup_location_id
       = pz.location_id

JOIN dim_zone dz
    ON f.dropoff_location_id
       = dz.location_id

WHERE
    pz.borough <> 'Unknown'
    AND dz.borough <> 'Unknown'

GROUP BY
    pz.zone,
    dz.zone

HAVING COUNT(*) >= 5000

ORDER BY total_revenue DESC

LIMIT 25;

-- ============================================================
-- 13. AIRPORT PICKUP PERFORMANCE
-- ============================================================

SELECT

    z.zone AS airport,

    COUNT(*) AS trips,

    ROUND(
        SUM(f.total_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(f.total_amount),
        2
    ) AS avg_revenue,

    ROUND(
        AVG(f.trip_distance),
        2
    ) AS avg_distance,

    ROUND(
        AVG(f.trip_duration_minutes),
        2
    ) AS avg_duration

FROM fact_trips f

JOIN dim_zone z
    ON f.pickup_location_id
       = z.location_id

WHERE z.zone IN (
    'JFK Airport',
    'LaGuardia Airport',
    'Newark Airport'
)

GROUP BY z.zone

ORDER BY total_revenue DESC;


-- ============================================================
-- 14. PAYMENT METHOD ANALYSIS
-- ============================================================

SELECT

    p.payment_method,

    COUNT(*) AS trips,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS trip_share_pct,

    ROUND(
        AVG(f.total_amount),
        2
    ) AS avg_trip_value

FROM fact_trips f

LEFT JOIN dim_payment p
    ON f.payment_type
       = p.payment_type

GROUP BY p.payment_method

ORDER BY trips DESC;

-- ============================================================
-- 15. CREDIT-CARD TIP BEHAVIOR
-- ============================================================

SELECT

    z.borough,

    COUNT(*) AS tipped_analysis_trips,

    ROUND(
        AVG(f.tip_amount),
        2
    ) AS avg_tip_amount,

    ROUND(
        AVG(f.tip_percentage),
        2
    ) AS avg_tip_percentage

FROM fact_trips f

JOIN dim_zone z
    ON f.pickup_location_id
       = z.location_id

WHERE
    f.valid_tip_analysis = TRUE
    AND z.borough NOT IN (
        'Unknown',
        'EWR'
    )

GROUP BY z.borough

ORDER BY avg_tip_percentage DESC;

-- ============================================================
-- 16. TOP 5 DEMAND ZONES WITHIN EACH BOROUGH
-- ============================================================

WITH zone_demand AS (

    SELECT

        z.borough,
        z.zone,

        COUNT(*) AS trips

    FROM fact_trips f

    JOIN dim_zone z
        ON f.pickup_location_id
           = z.location_id

    WHERE z.borough NOT IN (
        'Unknown',
        'EWR'
    )

    GROUP BY
        z.borough,
        z.zone
),

ranked AS (

    SELECT

        borough,
        zone,
        trips,

        DENSE_RANK()
        OVER (
            PARTITION BY borough
            ORDER BY trips DESC
        ) AS demand_rank

    FROM zone_demand
)

SELECT
    borough,
    zone,
    trips,
    demand_rank

FROM ranked

WHERE demand_rank <= 5

ORDER BY
    borough,
    demand_rank;