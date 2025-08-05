create database Household_Insights;

use Household_Insights;

select * from Categories;
select * from Data_Types;
select * from Error_Types;
select * from Geo_Levels;
select * from Time_Periods;
select * from Whole_Data;

-- 1. Total Households (National)
SELECT wd.val AS total_housing_units
FROM Whole_Data wd
JOIN Data_Types dt ON wd.dt_idx = dt.dt_idx
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 2 -- ESTIMATE
  AND wd.dt_idx = 5 -- TOTAL
  AND wd.geo_idx = 1 -- US
  AND wd.per_idx = 278; -- Q2-2025


-- 2. Total Occupied Housing Units (National)
SELECT wd.val AS occupied_housing_units
FROM Whole_Data wd
JOIN Data_Types dt ON wd.dt_idx = dt.dt_idx
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 2 -- ESTIMATE
  AND wd.dt_idx = 6 -- OCC
  AND wd.geo_idx = 1 -- US
  AND wd.per_idx = 278;

 -- 3. National Homeownership Percentage
SELECT wd.val AS homeownership_rate
FROM Whole_Data wd
JOIN Data_Types dt ON wd.dt_idx = dt.dt_idx
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.geo_idx = 1 -- US
  AND wd.per_idx = 278;

-- 4. Top 5 Regions by Homeownership Percentage
SELECT tOP 5 
gl.geo_desc, wd.val AS homeownership_rate
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.per_idx = 278
ORDER BY wd.val DESC;


-- 5. Bottom 5 Regions by Homeownership Percentage
SELECT TOP 5
gl.geo_desc, wd.val AS homeownership_rate
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.per_idx = 278
ORDER BY wd.val ASC;

-- 6. Regions with 65% Homeownership
SELECT gl.geo_desc, wd.val AS homeownership_rate
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.per_idx = 278
  AND wd.val >= 65; -- Assuming near-100% as 100% is unlikely

-- 7. Regions below National Average Homeownership
WITH national_avg AS (
  SELECT AVG(wd.val) AS avg_hor
  FROM Whole_Data wd
  WHERE wd.cat_idx = 1 -- RATE
    AND wd.dt_idx = 3 -- HOR
    AND wd.per_idx = 278
    AND wd.geo_idx != 1 -- Exclude US for regional average
)
SELECT gl.geo_desc, wd.val AS homeownership_rate
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
CROSS JOIN national_avg
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.per_idx = 278
  AND wd.geo_idx != 1 -- Exclude US
  AND wd.val < national_avg.avg_hor;

-- 8. Housing Gap per Region (Total - Occupied)
SELECT gl.geo_desc,
       total.val - occupied.val AS housing_gap
FROM (
  SELECT geo_idx, val
  FROM Whole_Data
  WHERE cat_idx = 2 -- ESTIMATE
    AND dt_idx = 5 -- TOTAL
    AND per_idx = 278
) total
JOIN (
  SELECT geo_idx, val
  FROM Whole_Data
  WHERE cat_idx = 2 -- ESTIMATE
    AND dt_idx = 6 -- OCC
    AND per_idx = 278
) occupied ON total.geo_idx = occupied.geo_idx
JOIN Geo_Levels gl ON total.geo_idx = gl.geo_idx;

-- 9. Average Homeownership Percentage (All Regions)
SELECT AVG(wd.val) AS avg_homeownership_rate
FROM Whole_Data wd
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.per_idx = 278
  AND wd.geo_idx != 1; -- Exclude US

-- 10. Region with Highest Housing Gap
SELECT TOP 1
gl.geo_desc,
       total.val - occupied.val AS housing_gap
FROM (
  SELECT geo_idx, val
  FROM Whole_Data
  WHERE cat_idx = 2 -- ESTIMATE
    AND dt_idx = 5 -- TOTAL
    AND per_idx = 278
) total
JOIN (
  SELECT geo_idx, val
  FROM Whole_Data
  WHERE cat_idx = 2 -- ESTIMATE
    AND dt_idx = 6 -- OCC
    AND per_idx = 278
) occupied ON total.geo_idx = occupied.geo_idx
JOIN Geo_Levels gl ON total.geo_idx = gl.geo_idx
ORDER BY housing_gap DESC;

-- 11. % Contribution of Each Region to National Housing Units
WITH national_total AS (
    SELECT val
    FROM Whole_Data
    WHERE cat_idx = 2
      AND dt_idx = 5
      AND geo_idx = 1
      AND per_idx = 278
)
SELECT 
    gl.geo_desc,
    (wd.val / NULLIF((SELECT val FROM national_total), 0)) * 100 AS percent_contribution
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
CROSS JOIN national_total
WHERE wd.cat_idx = 2
  AND wd.dt_idx = 5
  AND wd.per_idx = 278
  AND wd.geo_idx != 1;

-- 12. % Contribution of Each Region to Occupied Housing Units
WITH national_occupied AS (
    SELECT val
    FROM Whole_Data
    WHERE cat_idx = 2
      AND dt_idx = 6
      AND geo_idx = 1
      AND per_idx = 278
)
SELECT 
    gl.geo_desc,
    (wd.val / NULLIF((SELECT val FROM national_occupied), 0)) * 100 AS percent_contribution
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
CROSS JOIN national_occupied
WHERE wd.cat_idx = 2
  AND wd.dt_idx = 6
  AND wd.per_idx = 278
  AND wd.geo_idx != 1;

-- 13. Rank of Each Region by Homeownership %
SELECT gl.geo_desc,
       wd.val AS homeownership_rate,
       RANK() OVER (ORDER BY wd.val DESC) AS rank
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.per_idx = 278
  AND wd.geo_idx != 1;

-- 14. Rank of Each Region by Housing Unit Count
SELECT gl.geo_desc,
       wd.val AS total_housing_units,
       RANK() OVER (ORDER BY wd.val DESC) AS rank
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 2 -- ESTIMATE
  AND wd.dt_idx = 5 -- TOTAL
  AND wd.per_idx = 278
  AND wd.geo_idx != 1;

-- 15. Distribution: Regions by Homeownership % Ranges (0–50%, 51–75%, 76–99%, 100%)
SELECT gl.geo_desc,
       wd.val AS homeownership_rate,
       CASE
         WHEN wd.val <= 50 THEN '0-50%'
         WHEN wd.val <= 75 THEN '51-75%'
         ELSE '76-100%'
       END AS rate_range
FROM Whole_Data wd
JOIN Geo_Levels gl ON wd.geo_idx = gl.geo_idx
WHERE wd.cat_idx = 1 -- RATE
  AND wd.dt_idx = 3 -- HOR
  AND wd.per_idx = 278
  AND wd.geo_idx != 1
ORDER BY wd.val;