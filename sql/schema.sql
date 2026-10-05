DROP TABLE IF EXISTS fact_trips CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_zone CASCADE;
DROP TABLE IF EXISTS dim_payment CASCADE;


-- ============================================
-- ZONE DIMENSION
-- ============================================

CREATE TABLE dim_zone (
    location_id INTEGER PRIMARY KEY,
    borough VARCHAR(50),
    zone VARCHAR(100),
    service_zone VARCHAR(50)
);


-- ============================================
-- DATE DIMENSION
-- ============================================

CREATE TABLE dim_date (
    date_key DATE PRIMARY KEY,
    year SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    day SMALLINT NOT NULL,
    day_of_week SMALLINT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);


-- ============================================
-- PAYMENT DIMENSION
-- ============================================

CREATE TABLE dim_payment (
    payment_type SMALLINT PRIMARY KEY,
    payment_method VARCHAR(30) NOT NULL
);


-- ============================================
-- TRIP FACT TABLE
-- ============================================

CREATE TABLE fact_trips (

    trip_id BIGSERIAL PRIMARY KEY,

    vendor_id SMALLINT,

    pickup_datetime TIMESTAMP NOT NULL,
    dropoff_datetime TIMESTAMP NOT NULL,

    pickup_date DATE NOT NULL,

    pickup_location_id INTEGER,
    dropoff_location_id INTEGER,

    payment_type SMALLINT,

    passenger_count SMALLINT,

    trip_distance NUMERIC(10,2),
    trip_duration_minutes NUMERIC(10,2),
    avg_speed_mph NUMERIC(10,2),

    fare_amount NUMERIC(12,2),
    extra NUMERIC(10,2),
    mta_tax NUMERIC(10,2),
    tip_amount NUMERIC(12,2),
    tolls_amount NUMERIC(12,2),
    improvement_surcharge NUMERIC(10,2),
    total_amount NUMERIC(12,2),

    congestion_surcharge NUMERIC(10,2),
    airport_fee NUMERIC(10,2),
    cbd_congestion_fee NUMERIC(10,2),

    pickup_hour SMALLINT,
    pickup_weekday_num SMALLINT,

    is_weekend BOOLEAN,
    is_rush_hour BOOLEAN,

    revenue_per_mile NUMERIC(12,4),
    revenue_per_minute NUMERIC(12,4),
    tip_percentage NUMERIC(12,4),

    valid_tip_analysis BOOLEAN,
    valid_revenue_efficiency BOOLEAN,

    CONSTRAINT fk_pickup_zone
        FOREIGN KEY (pickup_location_id)
        REFERENCES dim_zone(location_id),

    CONSTRAINT fk_dropoff_zone
        FOREIGN KEY (dropoff_location_id)
        REFERENCES dim_zone(location_id),

    CONSTRAINT fk_pickup_date
        FOREIGN KEY (pickup_date)
        REFERENCES dim_date(date_key),

    CONSTRAINT fk_payment
        FOREIGN KEY (payment_type)
        REFERENCES dim_payment(payment_type)
);