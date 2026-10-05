-- ============================================
-- NYC TAXI ANALYTICAL INDEXES
-- ============================================


-- Temporal analysis
CREATE INDEX IF NOT EXISTS idx_fact_trips_pickup_datetime
ON fact_trips (pickup_datetime);


CREATE INDEX IF NOT EXISTS idx_fact_trips_pickup_date
ON fact_trips (pickup_date);


-- Geographic analysis
CREATE INDEX IF NOT EXISTS idx_fact_trips_pickup_location
ON fact_trips (pickup_location_id);


CREATE INDEX IF NOT EXISTS idx_fact_trips_dropoff_location
ON fact_trips (dropoff_location_id);


-- Route analysis
CREATE INDEX IF NOT EXISTS idx_fact_trips_route
ON fact_trips (
    pickup_location_id,
    dropoff_location_id
);


-- Time-of-day analysis
CREATE INDEX IF NOT EXISTS idx_fact_trips_pickup_hour
ON fact_trips (pickup_hour);


-- Payment analysis
CREATE INDEX IF NOT EXISTS idx_fact_trips_payment_type
ON fact_trips (payment_type);


-- Combined temporal + geographic analysis
CREATE INDEX IF NOT EXISTS idx_fact_trips_zone_datetime
ON fact_trips (
    pickup_location_id,
    pickup_datetime
);

CREATE INDEX IF NOT EXISTS idx_hourly_zone_date
ON mv_hourly_zone_metrics (
    pickup_date
);


CREATE INDEX IF NOT EXISTS idx_hourly_zone_location
ON mv_hourly_zone_metrics (
    pickup_location_id
);


CREATE INDEX IF NOT EXISTS idx_hourly_zone_date_hour
ON mv_hourly_zone_metrics (
    pickup_date,
    pickup_hour
);