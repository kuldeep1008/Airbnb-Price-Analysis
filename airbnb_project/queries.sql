-- ============================================================
-- Airbnb Price Analysis — London
-- Author  : Kuldeep Sharma
-- ============================================================

-- Create table
CREATE TABLE IF NOT EXISTS airbnb (
    id                   INT,
    name                 VARCHAR(200),
    neighbourhood        VARCHAR(100),
    room_type            VARCHAR(50),
    property_type        VARCHAR(50),
    bedrooms             DECIMAL(3,1),
    bathrooms            DECIMAL(3,1),
    accommodates         INT,
    price                DECIMAL(10,2),
    minimum_nights       INT,
    number_of_reviews    INT,
    review_scores_rating DECIMAL(3,1),
    availability_365     INT,
    amenities_count      INT,
    host_is_superhost    VARCHAR(1)
);

-- Q1: Average price by neighbourhood
SELECT neighbourhood,
       ROUND(AVG(price), 2)    AS avg_price,
       ROUND(MIN(price), 2)    AS min_price,
       ROUND(MAX(price), 2)    AS max_price,
       COUNT(*)                AS total_listings
FROM airbnb
WHERE price > 0 AND price < 1000
GROUP BY neighbourhood
ORDER BY avg_price DESC;

-- Q2: Average price by room type
SELECT room_type,
       ROUND(AVG(price), 2) AS avg_price,
       COUNT(*)              AS listings
FROM airbnb
WHERE price > 0
GROUP BY room_type
ORDER BY avg_price DESC;

-- Q3: Price increases with bedrooms
SELECT bedrooms,
       ROUND(AVG(price), 2) AS avg_price,
       COUNT(*)              AS listings
FROM airbnb
WHERE price > 0 AND bedrooms IS NOT NULL
GROUP BY bedrooms
ORDER BY bedrooms;

-- Q4: Superhost price premium
SELECT host_is_superhost,
       ROUND(AVG(price), 2)  AS avg_price,
       COUNT(*)               AS listings
FROM airbnb
WHERE price > 0
GROUP BY host_is_superhost;

-- Q5: Find undervalued listings using CTE
WITH neighbourhood_avg AS (
    SELECT neighbourhood,
           AVG(price) AS avg_price
    FROM airbnb
    WHERE price > 0
    GROUP BY neighbourhood
)
SELECT a.id,
       a.neighbourhood,
       a.room_type,
       a.price,
       ROUND(n.avg_price, 2)           AS neighbourhood_avg,
       a.review_scores_rating,
       a.number_of_reviews
FROM airbnb a
JOIN neighbourhood_avg n ON a.neighbourhood = n.neighbourhood
WHERE a.price < n.avg_price * 0.75
  AND a.review_scores_rating >= 4.5
  AND a.number_of_reviews >= 10
ORDER BY a.review_scores_rating DESC, a.price ASC
LIMIT 20;

-- Q6: Rank neighbourhoods using Window Function
SELECT neighbourhood,
       ROUND(AVG(price), 2) AS avg_price,
       COUNT(*) AS listings,
       RANK() OVER (ORDER BY AVG(price) DESC) AS price_rank
FROM airbnb
WHERE price > 0
GROUP BY neighbourhood;

-- Q7: Price percentiles per neighbourhood
SELECT neighbourhood,
       ROUND(AVG(price), 2)                          AS avg_price,
       ROUND(MAX(CASE WHEN pct <= 0.25 THEN price END), 2) AS p25,
       ROUND(MAX(CASE WHEN pct <= 0.50 THEN price END), 2) AS median,
       ROUND(MAX(CASE WHEN pct <= 0.75 THEN price END), 2) AS p75
FROM (
    SELECT neighbourhood, price,
           PERCENT_RANK() OVER (PARTITION BY neighbourhood ORDER BY price) AS pct
    FROM airbnb WHERE price > 0
) t
GROUP BY neighbourhood
ORDER BY avg_price DESC;
