INSERT INTO dim_payment (
    payment_type,
    payment_method
)
VALUES
    (0, 'Unknown'),
    (1, 'Credit Card'),
    (2, 'Cash'),
    (3, 'No Charge'),
    (4, 'Dispute'),
    (5, 'Unknown'),
    (6, 'Voided Trip')
ON CONFLICT (payment_type) DO NOTHING;

INSERT INTO dim_date (
    date_key,
    year,
    month,
    month_name,
    day,
    day_of_week,
    day_name,
    is_weekend
)

SELECT
    d::DATE,

    EXTRACT(YEAR FROM d)::SMALLINT,

    EXTRACT(MONTH FROM d)::SMALLINT,

    TO_CHAR(d, 'Month'),

    EXTRACT(DAY FROM d)::SMALLINT,

    EXTRACT(ISODOW FROM d)::SMALLINT,

    TO_CHAR(d, 'Day'),

    CASE
        WHEN EXTRACT(ISODOW FROM d) IN (6,7)
        THEN TRUE
        ELSE FALSE
    END

FROM generate_series(
    DATE '2025-01-01',
    DATE '2025-12-31',
    INTERVAL '1 day'
) AS d

ON CONFLICT (date_key)
DO NOTHING;