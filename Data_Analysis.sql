-- For this part, I answered all of the questions but not to take your time I will put the extras in the end in case you want to review!

-- What is the percentage of sales in the Health & Wellness category by generation?
WITH users_by_generation AS(
-- classifying users by generation
    SELECT
        ID,
        BIRTH_DATE,
        CASE
            WHEN BIRTH_DATE >= DATEADD(YEAR, -12, CURRENT_DATE())
                THEN 'GEN ALPHA' -- 2013-2025
            WHEN BIRTH_DATE >= DATEADD(YEAR, -28, CURRENT_DATE())
                THEN 'GEN Z' -- 1997-2012
            WHEN BIRTH_DATE >= DATEADD(YEAR, -44, CURRENT_DATE())
                THEN 'MILLENIALS' -- 1981-1996
            WHEN BIRTH_DATE >= DATEADD(YEAR, -60, CURRENT_DATE())
                THEN 'GEN X' -- 1965-1980
            WHEN BIRTH_DATE >= DATEADD(YEAR, -79, CURRENT_DATE())
                THEN 'BABY BOOMERS' -- 1946-1964
            WHEN BIRTH_DATE >= DATEADD(YEAR, -97, CURRENT_DATE())
                THEN 'SILENT GEN' -- 1928-1945
            ELSE 'GREATEST GEN' -- <1928
        END AS GENERATION
    FROM
        USERS
    WHERE
        BIRTH_DATE IS NOT NULL -- excluding users with unknown BIRTH_DATE field
)
,sales_by_user AS(
-- joining generation labeled users and TRANSACTIONS
    SELECT
        u.GENERATION,
        t.FINAL_SALE,
        t.BARCODE
    FROM
        TRANSACTIONS AS t
    INNER JOIN
        users_by_generation AS u
    ON
        t.USER_ID = u.ID
)
-- Summing the FINAL_SALE and calculating % for each GENERATION
SELECT
        su.GENERATION,
        SUM(su.FINAL_SALE) AS SALES_BY_GENERATION, -- summing the FINAL_SALE
        ROUND(SUM(su.FINAL_SALE) / SUM(SUM(su.FINAL_SALE)) OVER () * 100, 2) AS GENERATION_SHARE -- divide the generation sale by total sales
    FROM
        PRODUCTS AS p
    INNER JOIN
        sales_by_user AS su
    ON
        p.BARCODE = su.BARCODE
    WHERE
        p.CATEGORY_1 = 'Health & Wellness' -- filtering the 'Health & Wellness' category
    GROUP BY
        su.GENERATION
    ORDER BY
        SALES_BY_GENERATION DESC;
-- Baby Boomers 46.94%
-- Millenials 31.18%
-- Gen X 21.88%

-- Who are Fetch’s power users?
-- To figure that out, I have to understand the average users' behaviors and the data's capability.
-- Power users must use the app the most effectively, and figure out the app's feature the best.
-- The power user must have been a member for a while. Since I have window of 3 months TRANSACTIONS data, focusing on sign up date might be misleading
-- In order to identify 'Power User', I will consider the top 5-10% of the users (depending on the threshold) who scanned the most receipts.
-- After identifying the 'Power User', I need to come up with a metric that would describe them and that is meaningful for business goals.
-- There are 2 possible metric to understand about users; demographics (Generation, gender, language) and shopping behavior (Top Brands, categories, and stores they shop)
-- For short-term revenue & brand deals → Top Brands are more critical.
-- For long-term growth & user acquisition → Demographics provide valuable insights.
-- There is also 3rd things to consider, which is the data capability. There is much less common rows (258 rows) between TRANSACTIONS and USERS, so any insight will be less meaningfull due to data size. Therefore I will proceed with shopping behavior of the 'Power User's

WITH receipt_count AS(
-- counting # of receipts by user
    SELECT
        USER_ID,
        COUNT(*) AS RECEIPT_COUNT
    FROM
        TRANSACTIONS
    GROUP BY
        USER_ID
)
,receipt_average AS(
-- calculating the average # of receipts scanned and the threshold for top 10%
    SELECT
        USER_ID,
        RECEIPT_COUNT,
        ROUND(AVG(RECEIPT_COUNT) OVER(), 1) AS AVG_RECEIPT_NUMBER, -- average # of receipts scanned
        ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY RECEIPT_COUNT) OVER()) AS THRESHOLD -- threshold for top 10% (8% in reality)
    FROM
        receipt_count
    ORDER BY
        RECEIPT_COUNT DESC
)
,user_segment AS(
-- segmenting users based on the threshold
    SELECT
        USER_ID,
        RECEIPT_COUNT,
        CASE
            WHEN RECEIPT_COUNT > THRESHOLD
                THEN 'POWER USER' -- over threshold -> POWER USER
            ELSE 'CASUAL USER' -- under threshold -> CASUAL USER
        END AS USER_SEGMENT
    FROM
        receipt_average
    ORDER BY
        RECEIPT_COUNT DESC
)
,shopping AS(
-- understanding shopping behaviors of users
    SELECT
        p.BRAND,
        t.USER_ID,
        t.RECEIPT_ID
    FROM
        TRANSACTIONS AS t
    INNER JOIN
        PRODUCTS AS p
    ON
        t.BARCODE = p.BARCODE
)
-- matching USER_SEGMENT with shopping behaviors to see which brands users shop the most
SELECT
    s.BRAND,
    COUNT(s.RECEIPT_ID) AS COUNT
FROM
    shopping AS s
RIGHT JOIN
    user_segment AS us
ON
    s.USER_ID = us.USER_ID
WHERE
    us.USER_SEGMENT = 'POWER USER' -- filtering only Power Users
GROUP BY
    s.BRAND
ORDER BY
    COUNT DESC;
-- In conclusion, Fetch's 'Power User's are users who scanned the most receipt (top 8% percentile).
-- Power Users' top 5 brands are as follows:
-- 1. COCA-COLA
-- 2. GREAT VALUE
-- 3. EQUATE
-- 4. LAY'S
-- 5. PEPSI


-- At what percent has Fetch grown year over year?
-- TRANSACTIONS table captures the period between 2024-06-12 and 2024-09-08 which means that we cannot calculate the YoY growth by FINAL_SALE due to data capability
-- Also PRODUCTS table needs to be matched with TRANSACTIONS' date to calculate YoY, so we cannot know BRAND breakdown of YoY growth
-- By counting the new users each year, I can calculate the YoY growth.
-- I will also calculate 3 year and 5 year Compound Annual Growth Rate (CAGR), so that we can interpret the company's growth rate with 3 year and 5 year moving average.
WITH user_metrics AS(
-- Calculating new users, previous year's new users and running total by year.
    SELECT
        YEAR(CREATED_DATE) AS YEAR,
        COUNT(ID) AS NEW_USERS, -- # of new users
        LAG(COUNT(ID)) OVER (
            ORDER BY YEAR(CREATED_DATE)) AS PREVIOUS_YEAR, -- # of new users previous year
        SUM(COUNT(ID)) OVER (
            ORDER BY YEAR(CREATED_DATE) ROWS UNBOUNDED PRECEDING) AS TOTAL_USERS -- cumulative # of users
    FROM
        USERS
    GROUP BY
        YEAR
    ORDER BY
        YEAR
)
-- calculating 3 and 5 year Compound Annual Growth Rate (CAGR)
SELECT
    YEAR,
    NEW_USERS,
    TOTAL_USERS,
    LAG(TOTAL_USERS, 3) OVER(
        ORDER BY YEAR) AS USERS_3_YEARS_AGO, -- # of users 3 years ago
    LAG(TOTAL_USERS, 5) OVER(
        ORDER BY YEAR) AS USERS_5_YEARS_AGO, -- # of users 5 years ago
    ROUND((TOTAL_USERS / LAG(TOTAL_USERS) OVER (
        ORDER BY YEAR) -1) * 100, 1) AS YoY_Growth_Rate, -- YoY growth rate
    ROUND((POWER(TOTAL_USERS / NULLIF(USERS_3_YEARS_AGO, 0), (1/3)) - 1) * 100, 1) AS CAGR_3_YEARS, -- last 3 years' compound growth rate
    ROUND((POWER(TOTAL_USERS / NULLIF(USERS_5_YEARS_AGO, 0), (1/5)) - 1) * 100, 1) AS CAGR_5_YEARS -- last 5 years' compound growth rate
FROM
    user_metrics;
-- We can clearly see that Fetch's user growth is declining every year
-- YoY growth peaked in 2017
-- In order to interpret the growth rate, I also added 3 years and 5 years CAGR to identify If the company is in accelerated or decelerated growth
-- In order to grasp this results better, I will create a chart in Tableau.