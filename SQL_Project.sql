CREATE DATABASE IF NOT EXISTS atliq_hospitality_db;
USE atliq_hospitality_db;

# STEP 1: DATA IMPORTING & CLEANING
-- ----------------------------------------------------------------------------

DROP TABLE IF EXISTS fact_bookings;
CREATE TABLE fact_bookings (
    booking_id VARCHAR(50) PRIMARY KEY,
    property_id INT,
    booking_date DATE,
    check_in_date DATE,
    checkout_date DATE,
    no_guests INT,
    room_category VARCHAR(10),
    booking_platform VARCHAR(50),
    ratings_given TINYINT,
    booking_status VARCHAR(50),
    revenue_generated DECIMAL(12,2),
    revenue_realized DECIMAL(12,2)
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE "D:/1st Project- Hospitality Analytics/fact_bookings.csv"
INTO TABLE atliq_hospitality_db.fact_bookings
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' -- Use '\r\n' if created on Windows
IGNORE 1 LINES;

select * from fact_bookings;

-- STEP 2: DATA CLEANING

SET SQL_SAFE_UPDATES = 0;

-- Correct the known spelling error in dim_date, if present.
UPDATE dim_date
SET day_type = 'weekday'
WHERE LOWER(TRIM(day_type)) = 'weekeday';
select * from dim_date;

-- Remove extra spaces from text fields.
UPDATE dim_hotels
SET property_name = TRIM(property_name),
    category = TRIM(category),
    city = TRIM(city);

UPDATE fact_bookings
SET booking_platform = TRIM(booking_platform),
    booking_status = TRIM(booking_status);

SET SQL_SAFE_UPDATES = 1;

-- Data quality check: invalid revenue or checkout dates (expected result: 0).
SELECT COUNT(*) AS invalid_records
FROM fact_bookings
WHERE revenue_realized < 0
   OR revenue_generated < 0
   OR (check_in_date IS NOT NULL AND checkout_date IS NOT NULL
       AND check_in_date > checkout_date);

# SECTION 3: DASHBOARD PAGE 1 QUERIES 

# Query 1.1: Core Overview KPIs

WITH fb_summary AS (                                          
    SELECT 
        SUM(revenue_realized) AS total_revenue,SUM(COALESCE(revenue_generated, 0) -COALESCE(revenue_realized, 0)) AS revenue_leakage,
        COUNT(booking_id) AS total_bookings,
        SUM(CASE WHEN booking_status = 'Checked Out' THEN 1 ELSE 0 END) AS checked_out,
        SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
        SUM(CASE WHEN booking_status = 'No Show' THEN 1 ELSE 0 END) AS no_show,
        ROUND(AVG(NULLIF(CAST(ratings_given AS UNSIGNED), 0)), 2) AS avg_rating
    FROM fact_bookings
),
fa_summary AS (
    SELECT 
        SUM(capacity) AS total_capacity,
        SUM(successful_bookings) AS total_agg_bookings
    FROM fact_aggregated_bookings
)
SELECT 
    ROUND(fb.total_revenue / 1000000.0, 1) AS revenue_in_millions,
    fb.total_bookings,
    ROUND(fb.checked_out * 100.0 / NULLIF(fb.total_bookings, 0), 1) AS realisation_pct,
    ROUND(fb.cancelled * 100.0 / NULLIF(fb.total_bookings, 0), 1) AS cancellation_pct,
    ROUND(fb.no_show * 100.0 / NULLIF(fb.total_bookings, 0), 1) AS no_show_pct,
    ROUND(fb.revenue_leakage / 1000000.0, 1) AS leakage_in_millions,
    ROUND(fa.total_agg_bookings * 100.0 / NULLIF(fa.total_capacity, 0), 1) AS occ_booked_pct,
    ROUND(fb.checked_out * 100.0 / NULLIF(fa.total_capacity, 0), 1) AS occ_realized_pct,
    ROUND(fb.total_revenue / NULLIF(fb.total_bookings, 0), 0) AS adr,
    ROUND(fb.total_revenue / NULLIF(fa.total_capacity, 0), 0) AS revpar,
    fb.avg_rating
FROM fb_summary fb
CROSS JOIN fa_summary fa;

-- Query 1.2: Performance by City (RevPAR & Occupancy Booked vs Realized)

WITH city_bookings AS (
    SELECT 
        dh.city,
        SUM(fb.revenue_realized) AS revenue,
        SUM(CASE WHEN fb.booking_status = 'Checked Out' THEN 1 ELSE 0 END) AS checked_out
    FROM fact_bookings fb
    JOIN dim_hotels dh ON fb.property_id = dh.property_id
    GROUP BY dh.city
),
city_capacity AS (
    SELECT 
        dh.city,
        SUM(fa.capacity) AS total_capacity,
        SUM(fa.successful_bookings) AS total_agg_bookings
    FROM fact_aggregated_bookings fa
    JOIN dim_hotels dh ON fa.property_id = dh.property_id
    GROUP BY dh.city
)
SELECT 
    cb.city,
    ROUND(cb.revenue / NULLIF(cc.total_capacity, 0), 0) AS revpar,
   ROUND(
    cc.total_agg_bookings * 100.0 /
    NULLIF(cc.total_capacity, 0), 1
) AS occ_booked_pct,
    ROUND(cb.checked_out * 100.0 / NULLIF(cc.total_capacity, 0), 1) AS occ_realized_pct
FROM city_bookings cb
JOIN city_capacity cc ON cb.city = cc.city
ORDER BY revpar DESC;

-- Query 1.3: Booking Share and Cancellation Rate by Platform

SELECT 
    booking_platform,
    COUNT(booking_id) AS total_bookings,
    ROUND(COUNT(booking_id) * 100.0 / NULLIF((SELECT COUNT(*) FROM fact_bookings), 0), 1) AS booking_share_pct,
    ROUND(SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(booking_id), 0), 1) AS cancellation_pct
FROM fact_bookings
GROUP BY booking_platform
ORDER BY total_bookings DESC;


-- Query 1.4: Guest Rating Breakdown by Star Rating

SELECT
    CAST(TRIM(ratings_given) AS UNSIGNED) AS star_rating,
    COUNT(booking_id) AS total_ratings
FROM fact_bookings
WHERE ratings_given IS NOT NULL
  AND TRIM(ratings_given) REGEXP '^[0-9]+$'
GROUP BY CAST(TRIM(ratings_given) AS UNSIGNED)
ORDER BY star_rating DESC;


## Query 1.5: Top 5 Properties by Revenue Leakage:

WITH prop_bookings AS (
    SELECT 
        fb.property_id,
       SUM(COALESCE(revenue_generated, 0) -COALESCE(revenue_realized, 0)) AS revenue_leakage,
        SUM(fb.revenue_realized) AS revenue,
        COUNT(fb.booking_id) AS total_bookings,
        SUM(CASE WHEN fb.booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled
    FROM fact_bookings fb
    GROUP BY fb.property_id
),
prop_capacity AS (
    SELECT 
        property_id,
        SUM(capacity) AS total_capacity
    FROM fact_aggregated_bookings
    GROUP BY property_id
)
SELECT 
    dh.property_name,
    dh.city,
    dh.property_id,
    ROUND(pb.revenue_leakage / 1000000, 1) AS leakage_millions,
    ROUND(pb.cancelled * 100.0 / NULLIF(pb.total_bookings, 0), 1) AS cancellation_pct,
    ROUND(pb.revenue / NULLIF(pc.total_capacity, 0), 0) AS revpar
FROM prop_bookings pb
JOIN prop_capacity pc ON pb.property_id = pc.property_id
JOIN dim_hotels dh ON pb.property_id = dh.property_id
ORDER BY pb.revenue_leakage DESC
LIMIT 5;

# 1.6 Occupancy by City:

WITH booked AS (
    SELECT
        h.city,
        SUM(a.successful_bookings) AS bookings,
        SUM(a.capacity) AS capacity
    FROM fact_aggregated_bookings a
    JOIN dim_hotels h
        ON a.property_id = h.property_id
    GROUP BY h.city
),
realized AS (
    SELECT
        h.city,
        COUNT(*) AS checkouts
    FROM fact_bookings b
    JOIN dim_hotels h
        ON b.property_id = h.property_id
    WHERE b.booking_status = 'Checked Out'
    GROUP BY h.city
)
SELECT
    booked.city,
    ROUND(booked.bookings * 100.0 / NULLIF(booked.capacity, 0), 1) AS booked_occupancy,
    ROUND(COALESCE(checkouts, 0) * 100.0 / NULLIF(capacity, 0), 1)
        AS realized_occupancy
FROM booked
LEFT JOIN realized
    ON booked.city = realized.city
ORDER BY booked.city;


# 1.7 Booking Status:

SELECT 
    booking_status,
    COUNT(*) AS total_bookings,
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (), 
        1
    ) AS percentage
FROM fact_bookings
GROUP BY booking_status
ORDER BY total_bookings DESC;

-- SECTION 4: DASHBOARD PAGE 2 QUERIES (Weekly & Day-Wise Fluctuations):

-- Query 2.1: Daily Room Metrics (DBRN, DSRN, DURN)

WITH days_cnt AS (
    SELECT COUNT(DISTINCT date) AS total_days FROM dim_date
),
fb_counts AS (
    SELECT 
        COUNT(booking_id) AS total_bookings,
        SUM(CASE WHEN booking_status = 'Checked Out' THEN 1 ELSE 0 END) AS checked_out
    FROM fact_bookings
),
fa_counts AS (
    SELECT SUM(capacity) AS total_capacity FROM fact_aggregated_bookings
)
SELECT 
    ROUND(fb.total_bookings / d.total_days, 0) AS DBRN,
    ROUND(fa.total_capacity / d.total_days, 0) AS DSRN,
    ROUND(fb.checked_out / d.total_days, 0) AS DURN
FROM fb_counts fb, fa_counts fa, days_cnt d;

-- Query 2.2: Weekday vs Weekend Comparison

WITH day_bookings AS (
    SELECT 
        dd.day_type,
        COUNT(fb.booking_id) AS total_bookings,
        SUM(fb.revenue_realized) AS total_revenue,
        SUM(CASE WHEN fb.booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
        COUNT(DISTINCT dd.date) AS num_days
    FROM fact_bookings fb
    JOIN dim_date dd ON fb.check_in_date = dd.date
    GROUP BY dd.day_type
),
day_capacity AS (
    SELECT 
        dd.day_type,
        SUM(fa.capacity) AS total_capacity,
        SUM(fa.successful_bookings) AS total_agg_bookings
    FROM fact_aggregated_bookings fa
    JOIN dim_date dd ON fa.check_in_date = dd.date
    GROUP BY dd.day_type
)
SELECT 
    db.day_type,
    ROUND(dc.total_agg_bookings * 100.0 / dc.total_capacity, 1) AS occ_booked_pct,
    ROUND(db.cancelled_bookings * 100.0 /NULLIF(db.total_bookings, 0), 1) AS cancellation_pct,
    ROUND((db.total_revenue / db.num_days) / 1000000, 1) AS avg_daily_revenue_millions
FROM day_bookings db
JOIN day_capacity dc ON db.day_type = dc.day_type;

-- Query 2.3: Booked Occupancy % by Day of Week

SELECT 
    DAYNAME(fa.check_in_date) AS day_name,
    ROUND(SUM(fa.successful_bookings) * 100.0 /NULLIF(SUM(fa.capacity), 0),1) AS occ_booked_pct
FROM fact_aggregated_bookings fa
GROUP BY DAYNAME(fa.check_in_date), DAYOFWEEK(fa.check_in_date)
ORDER BY DAYOFWEEK(fa.check_in_date);

-- Query 2.4: Weekly Performance & Week-over-Week (WoW) Change:
WITH fb_weekly AS (
    SELECT 
        dd.`week no` AS raw_week,
        MIN(dd.date) AS week_start_date,
        SUM(fb.revenue_realized) AS revenue
    FROM dim_date dd
    JOIN fact_bookings fb 
        ON dd.date = fb.check_in_date
    GROUP BY dd.`week no`
),
fa_weekly AS (
    SELECT 
        dd.`week no` AS raw_week,
        SUM(fa.capacity) AS total_capacity,
        SUM(fa.successful_bookings) AS total_agg_bookings
    FROM dim_date dd
    JOIN fact_aggregated_bookings fa 
        ON dd.date = fa.check_in_date
    GROUP BY dd.`week no`
),
combined AS (
    SELECT 
        fb.week_start_date,
        -- Generate sequential week rank (1 for W19, 2 for W20 ... 14 for W32)
        DENSE_RANK() OVER (ORDER BY fb.week_start_date) AS week_seq,
        CONCAT('W', DENSE_RANK() OVER (ORDER BY fb.week_start_date)) AS week_no,
        fb.revenue,
        fa.total_capacity,
        fa.total_agg_bookings,
        (fa.total_agg_bookings * 100.0 / NULLIF(fa.total_capacity, 0)) AS occ_pct_raw,
        (fb.revenue * 1.0 /NULLIF(fa.total_agg_bookings, 0)) AS adr_raw,
		(fb.revenue * 1.0 / NULLIF(fa.total_capacity, 0)) AS revpar_raw
    FROM fb_weekly fb
    JOIN fa_weekly fa 
        ON fb.raw_week = fa.raw_week
),
filtered AS (
    SELECT *
    FROM combined
    WHERE week_seq <= 13 -- Keep only full weeks W1 to W13; excludes W14 (31st Jul)
)
SELECT 
    week_no,
    ROUND(revenue / 1000000.0, 1) AS revenue_millions,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY week_start_date)) * 100.0 
        / NULLIF(LAG(revenue) OVER (ORDER BY week_start_date), 0), 1
    ) AS revenue_wow_pct,
    
    ROUND(occ_pct_raw, 1) AS occ_pct,
    ROUND(
        (occ_pct_raw - LAG(occ_pct_raw) OVER (ORDER BY week_start_date)) * 100.0 
        / NULLIF(LAG(occ_pct_raw) OVER (ORDER BY week_start_date), 0), 1
    ) AS occ_wow_pct,
    
    ROUND(adr_raw, 0) AS adr,
    ROUND(
        (adr_raw - LAG(adr_raw) OVER (ORDER BY week_start_date)) * 100.0 
        / NULLIF(LAG(adr_raw) OVER (ORDER BY week_start_date), 0), 1
    ) AS adr_wow_pct,
    
    ROUND(revpar_raw, 0) AS revpar,
    ROUND(
        (revpar_raw - LAG(revpar_raw) OVER (ORDER BY week_start_date)) * 100.0 
        / NULLIF(LAG(revpar_raw) OVER (ORDER BY week_start_date), 0), 1
    ) AS revpar_wow_pct
FROM filtered
ORDER BY week_start_date;

# Query 2.5 : Occupancy % heatmap,week x day

SELECT
    CASE 
        WHEN d.`week no` IN ('W32', '32') THEN 'W14*'
        ELSE CONCAT('W', CAST(REPLACE(d.`week no`, 'W', '') AS UNSIGNED) - 18)
    END AS `Wk`,
    ROUND(SUM(CASE WHEN DAYNAME(d.date) = 'Sunday'    THEN a.successful_bookings END) * 100.0 / NULLIF(SUM(CASE WHEN DAYNAME(d.date) = 'Sunday'    THEN a.capacity END), 0), 0) AS Sun,
    ROUND(SUM(CASE WHEN DAYNAME(d.date) = 'Monday'    THEN a.successful_bookings END) * 100.0 / NULLIF(SUM(CASE WHEN DAYNAME(d.date) = 'Monday'    THEN a.capacity END), 0), 0) AS Mon,
    ROUND(SUM(CASE WHEN DAYNAME(d.date) = 'Tuesday'   THEN a.successful_bookings END) * 100.0 / NULLIF(SUM(CASE WHEN DAYNAME(d.date) = 'Tuesday'   THEN a.capacity END), 0), 0) AS Tue,
    ROUND(SUM(CASE WHEN DAYNAME(d.date) = 'Wednesday' THEN a.successful_bookings END) * 100.0 / NULLIF(SUM(CASE WHEN DAYNAME(d.date) = 'Wednesday' THEN a.capacity END), 0), 0) AS Wed,
    ROUND(SUM(CASE WHEN DAYNAME(d.date) = 'Thursday'  THEN a.successful_bookings END) * 100.0 / NULLIF(SUM(CASE WHEN DAYNAME(d.date) = 'Thursday'  THEN a.capacity END), 0), 0) AS Thu,
    ROUND(SUM(CASE WHEN DAYNAME(d.date) = 'Friday'    THEN a.successful_bookings END) * 100.0 / NULLIF(SUM(CASE WHEN DAYNAME(d.date) = 'Friday'    THEN a.capacity END), 0), 0) AS Fri,
    ROUND(SUM(CASE WHEN DAYNAME(d.date) = 'Saturday'  THEN a.successful_bookings END) * 100.0 / NULLIF(SUM(CASE WHEN DAYNAME(d.date) = 'Saturday'  THEN a.capacity END), 0), 0) AS Sat
FROM fact_aggregated_bookings a
JOIN dim_date d
    ON a.check_in_date = d.date
GROUP BY d.`week no`
ORDER BY MIN(d.date);


# 2.6 Weekly Revenue and Booked Occupancy:
WITH revenue AS (
    SELECT
        d.`week no` AS wk,
        MIN(d.date) AS first_date,
        SUM(b.revenue_realized) AS total_revenue
    FROM fact_bookings b
    JOIN dim_date d
        ON b.check_in_date = d.date
    GROUP BY d.`week no`
),

occupancy AS (
    SELECT
        d.`week no` AS wk,
        ROUND(
            SUM(a.successful_bookings) * 100.0 /
            NULLIF(SUM(a.capacity), 0), 1
        ) AS occupancy_pct
    FROM fact_aggregated_bookings a
    JOIN dim_date d
        ON a.check_in_date = d.date
    GROUP BY d.`week no`
)

SELECT
    CONCAT(
        'W',
        ROW_NUMBER() OVER (ORDER BY r.first_date),
        CASE
            WHEN r.first_date = '2022-07-31'
            THEN '*'
            ELSE ''
        END
    ) AS week,

    ROUND(r.total_revenue / 1000000, 1)
        AS revenue_m,

    o.occupancy_pct

FROM revenue r
JOIN occupancy o
    ON r.wk = o.wk

ORDER BY r.first_date;



