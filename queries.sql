-- queries.sql
-- Churn analysis for the bank customer dataset.
-- Run after loading the data (see README):
--   sqlite3 -header -column churn.db < queries.sql

-- ---------------------------------------------------------------
-- Q1. Headline: how many customers churned overall?
--     exited = 1 means the customer left. SUM(exited) counts the
--     leavers; the 100.0 forces decimal (not integer) division.
-- ---------------------------------------------------------------
SELECT COUNT(*)                                  AS total_customers,
       SUM(exited)                               AS churned,
       ROUND(100.0 * SUM(exited) / COUNT(*), 1)  AS churn_rate_pct
FROM customers;

-- ---------------------------------------------------------------
-- Q2. Churn by number of products held (the standout finding).
-- ---------------------------------------------------------------
SELECT num_products,
       COUNT(*)                                  AS customers,
       SUM(exited)                               AS churned,
       ROUND(100.0 * SUM(exited) / COUNT(*), 1)  AS churn_rate_pct
FROM customers
GROUP BY num_products
ORDER BY num_products;

-- ---------------------------------------------------------------
-- Q3. Churn by age band. CASE buckets the raw age into groups.
-- ---------------------------------------------------------------
SELECT CASE
         WHEN age < 30 THEN '18-29'
         WHEN age < 40 THEN '30-39'
         WHEN age < 50 THEN '40-49'
         WHEN age < 60 THEN '50-59'
         ELSE '60+'
       END                                       AS age_band,
       COUNT(*)                                  AS customers,
       ROUND(100.0 * SUM(exited) / COUNT(*), 1)  AS churn_rate_pct
FROM customers
GROUP BY age_band
ORDER BY age_band;

-- ---------------------------------------------------------------
-- Q4. Churn by country.
-- ---------------------------------------------------------------
SELECT geography,
       COUNT(*)                                  AS customers,
       ROUND(100.0 * SUM(exited) / COUNT(*), 1)  AS churn_rate_pct
FROM customers
GROUP BY geography
ORDER BY churn_rate_pct DESC;

-- ---------------------------------------------------------------
-- Q5. Churn by activity, gender, and whether they hold a balance.
-- ---------------------------------------------------------------
SELECT CASE is_active_member WHEN 1 THEN 'active' ELSE 'inactive' END AS member_status,
       COUNT(*)                                  AS customers,
       ROUND(100.0 * SUM(exited) / COUNT(*), 1)  AS churn_rate_pct
FROM customers
GROUP BY is_active_member
ORDER BY churn_rate_pct DESC;

SELECT gender,
       COUNT(*)                                  AS customers,
       ROUND(100.0 * SUM(exited) / COUNT(*), 1)  AS churn_rate_pct
FROM customers
GROUP BY gender
ORDER BY churn_rate_pct DESC;

-- ---------------------------------------------------------------
-- Q6. "Where are the lost customers?" — rate vs VOLUME.
--     A high rate on a tiny group loses fewer people than a
--     moderate rate on a huge group. This ranks segments by the
--     actual NUMBER of churned customers. (Segments overlap, so
--     these do not add up to the total.)
-- ---------------------------------------------------------------
SELECT 'single product (1)' AS segment, COUNT(*) AS customers, SUM(exited) AS churned, ROUND(100.0*SUM(exited)/COUNT(*),1) AS churn_rate_pct FROM customers WHERE num_products = 1
UNION ALL SELECT 'inactive members', COUNT(*), SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE is_active_member = 0
UNION ALL SELECT 'female',           COUNT(*), SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE gender = 'Female'
UNION ALL SELECT 'Germany',          COUNT(*), SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE geography = 'Germany'
UNION ALL SELECT 'age 50-59',        COUNT(*), SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE age BETWEEN 50 AND 59
UNION ALL SELECT '3-4 products',     COUNT(*), SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE num_products >= 3
ORDER BY churned DESC;
