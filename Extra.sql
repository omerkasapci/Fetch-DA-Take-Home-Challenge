-- EXTRA

-- What are the top 5 brands by receipts scanned among users 21 and over?
WITH age_limit AS(
-- Filtering the user If they are 21 years old or not
    SELECT
        ID
    FROM
        USERS
    WHERE
        DATEADD(YEAR, -21, CURRENT_DATE()) >= DATE(BIRTH_DATE) -- used DATEADD() in case DATEDIFF() might cause problems because of rounding
)
,receipts_over_21 AS(
-- joining the USERS and TRANSACTIONS tables
    SELECT
        t.RECEIPT_ID,
        t.BARCODE
    FROM
        TRANSACTIONS AS t
    INNER JOIN
        age_limit AS a
    ON
        t.USER_ID = a.ID
)
-- counting the RECEIPT_ID by BRAND
SELECT
    p.BRAND,
    COUNT(r.RECEIPT_ID) AS RECEIPT_NUMBER
FROM
    PRODUCTS AS p
INNER JOIN
    receipts_over_21 AS r
ON
    p.BARCODE = r.BARCODE
WHERE
    p.BRAND IS NOT NULL -- I do not want NULL in the top 5 BRANDS
GROUP BY
    p.BRAND
ORDER BY
    RECEIPT_NUMBER DESC
LIMIT 5 -- top 5 brands


-- What are the top 5 brands by sales among users that have had their account for at least six months?
WITH account_limit AS(
-- Filtering the user If they have had their account for 6 months
    SELECT
        ID,
        DATEDIFF(MONTH, DATE(CREATED_DATE), CURRENT_DATE()) AS MEMBER_PERIOD -- calculating how long the users had their account (MONTHS)
    FROM
        USERS
    WHERE
        DATEADD(MONTH, -6, CURRENT_DATE()) >= DATE(CREATED_DATE) -- used DATEADD() in case DATEDIFF() might cause problems because of rounding
)
,receipts_6_months AS(
-- joining the USERS and TRANSACTIONS tables
    SELECT
        t.FINAL_SALE,
        t.BARCODE,
    FROM
        TRANSACTIONS AS t  
    INNER JOIN
        account_limit AS u
    ON
        t.USER_ID = u.ID
)
-- Summing the FINAL_SALE by BRAND
SELECT
    p.BRAND,
    COUNT(r.FINAL_SALE) AS TOTAL_SALES
FROM
    PRODUCTS AS p
INNER JOIN
    receipts_6_months AS r
ON
    p.BARCODE = r.BARCODE
WHERE
    p.BRAND IS NOT NULL -- I do not want NULL in the top 5 BRANDS
GROUP BY
    p.BRAND
ORDER BY
    TOTAL_SALES DESC
LIMIT 5 -- top 5 brands

-- Which is the leading brand in the Dips & Salsa category?
WITH consolidated AS(
    SELECT
        t.USER_ID,
        t.RECEIPT_ID,
        t.BARCODE,
        t.FINAL_QUANTITY,
        t.FINAL_SALE,
        p.CATEGORY_2,
        p.BRAND
    FROM
        PRODUCTS AS p
    INNER JOIN
        TRANSACTIONS AS t
    ON
        p.BARCODE = t.BARCODE
)
SELECT
    BRAND,
    SUM(FINAL_SALE) AS SALES,
    COUNT(RECEIPT_ID) AS RECEIPT_NUMBER,
    ROUND(SUM(FINAL_SALE) / COUNT(RECEIPT_ID), 2) AS AVG_SALES_PER_RECEIPT
FROM
    consolidated
WHERE
    BRAND IS NOT NULL -- excluding NULLs in BRANDs
AND
    CATEGORY_2 = 'Dips & Salsa' -- filtering only 'Dips & Salsa' category
GROUP BY
    BRAND
ORDER BY
    SALES DESC