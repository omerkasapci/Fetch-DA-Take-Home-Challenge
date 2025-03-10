-- DATA EXPLORATION - PRODUCTS TABLE

-- Data Preview
SELECT
    *
FROM
    PRODUCTS
ORDER BY
    BARCODE;

-- check for NULL values
SELECT
    COUNT(*) AS TOTAL_ROWS, -- Total number of rows
    COUNT(*) - COUNT(BARCODE) AS BARCODE_NULLS, -- Subtracting the total rows to get the number of NULL values
    COUNT(*) - COUNT(CATEGORY_1) AS CATEGORY_1_NULLS,
    COUNT(*) - COUNT(CATEGORY_2) AS CATEGORY_2_NULLS,
    COUNT(*) - COUNT(CATEGORY_3) AS CATEGORY_3_NULLS,
    COUNT(*) - COUNT(CATEGORY_4) AS CATEGORY_4_NULLS,
    COUNT(*) - COUNT(MANUFACTURER) AS MANUFACTURER_NULLS,
    COUNT(*) - COUNT(BRAND) AS BRAND_NULLS
FROM
    PRODUCTS;
-- # of NULL values in each field is as follows:
-- BARCODE : 4025
-- CATEGORY_1 : 111
-- CATEGORY_2 : 1424
-- CATEGORY_3 : 60566
-- CATEGORY_4 : 778093
-- MANUFACTURER : 226474
-- BRAND : 226472

-- check the duplicates
DELETE FROM
    PRODUCTS
WHERE
    BARCODE IN( -- filtering the barcodes with duplicate rows
        SELECT
            BARCODE -- pulling a list of barcodes
        FROM(
            SELECT
                BARCODE,
                CATEGORY_1,
                CATEGORY_2,
                CATEGORY_3,
                CATEGORY_4,
                MANUFACTURER,
                BRAND,
                COUNT(*) AS COUNT
            FROM
                PRODUCTS
            GROUP BY
                BARCODE,
                CATEGORY_1,
                CATEGORY_2,
                CATEGORY_3,
                CATEGORY_4,
                MANUFACTURER,
                BRAND
            HAVING
                COUNT(*) > 1
    )
);
-- 316 duplicate rows are deleted

-- check if every barcode is unique
SELECT
    BARCODE,
    COUNT(*)
FROM
    PRODUCTS
WHERE
    BARCODE IS NOT NULL -- excluding the NULL values because they are just incomplete data not duplicates
GROUP BY
    BARCODE
HAVING
    COUNT(*) > 1; -- filtering the duplicates
-- 27 'BARCODE' is not UNIQUE



-- DATA EXPLORATION - TRANSACTIONS TABLE

-- See what the data looks like to dive deeper
SELECT
    *
FROM
    TRANSACTIONS
ORDER BY
    RECEIPT_ID;

-- check the nulls
SELECT
    COUNT(*) AS TOTAL_ROWS, -- Total number of rows
    COUNT(*) - COUNT(RECEIPT_ID) AS RECEIPT_ID_NULLS, -- Subtracting the total rows to get the number of NULL values
    COUNT(*) - COUNT(PURCHASE_DATE) AS PURCHASE_DATE_NULLS,
    COUNT(*) - COUNT(SCAN_DATE) AS SCAN_DATE_NULLS,
    COUNT(*) - COUNT(STORE_NAME) AS STORE_NAME_NULLS,
    COUNT(*) - COUNT(USER_ID) AS USER_ID_NULLS,
    COUNT(*) - COUNT(BARCODE) AS BARCODE_ID_NULLS,
    COUNT(*) - COUNT(FINAL_QUANTITY) AS FINAL_QUANTITY_NULLS,
    COUNT(*) - COUNT(FINAL_SALE) AS FINAL_SALE_NULLS
FROM
    TRANSACTIONS;
-- Barcode ID column has 5762 NULL values. Since it is the primary key in 'Products' table we cannot know the details!
-- Also 'final_sale' field has 12500 NULL values, which is 25% of the rows!

-- check why is 'final_quantity' is not a numeric field
SELECT
    DISTINCT FINAL_QUANTITY
FROM
    TRANSACTIONS
    
-- because value '0' is typed as 'zero', we can replace the 'zero' with '0'
UPDATE
    TRANSACTIONS
SET
    FINAL_QUANTITY = '0.00' -- because the rest of the data format is double
WHERE
    FINAL_QUANTITY = 'zero';
-- the column now can be converted to number format

-- Delete duplicate rows
DELETE FROM
    TRANSACTIONS
WHERE RECEIPT_ID IN (
    SELECT
        RECEIPT_ID
    FROM(
        SELECT
    RECEIPT_ID,
    PURCHASE_DATE,
    SCAN_DATE,
    STORE_NAME,
    USER_ID,
    BARCODE,
    FINAL_QUANTITY,
    FINAL_SALE,
    COUNT(*) AS DUPLICATE_COUNT
FROM
    TRANSACTIONS
GROUP BY
    RECEIPT_ID,
    PURCHASE_DATE,
    SCAN_DATE,
    STORE_NAME,
    USER_ID,
    BARCODE,
    FINAL_QUANTITY,
    FINAL_SALE
HAVING
    COUNT(*) > 1 -- check if there is more than one of any row
    )
);
-- 568 duplicate rows are deleted

-- In transactions table, 'user_id' and 'barcode' fields are foreign key.
-- I assumed that every transaction is a receipt which makes 'receipt_id' column is the primary key
-- That's why I also wanted to check duplicates in 'receipt_id' field
SELECT
    RECEIPT_ID,
    COUNT(*) AS COUNT
FROM
    TRANSACTIONS
GROUP BY
    RECEIPT_ID
HAVING
    COUNT(*) = 1; -- check if my assummption is correct
-- Each receipt_id appears in more than one row, which shows that it is not primary key

-- excluding 'final_quantity' and 'final_sale' fields to see if the multiple 'receipt_id's differentiates in these columns
SELECT
    RECEIPT_ID,
    PURCHASE_DATE,
    SCAN_DATE,
    STORE_NAME,
    USER_ID,
    BARCODE,
    COUNT(*) AS COUNT
FROM
    TRANSACTIONS
GROUP BY
    RECEIPT_ID,
    PURCHASE_DATE,
    SCAN_DATE,
    STORE_NAME,
    USER_ID,
    BARCODE
HAVING
    COUNT(*) = 1; -- I want to see If I will get any rows returned unlike the previous query
-- since there is no rows returned, we can say the multiple 'receipt_id's differentiates in 'final_quantity' and 'final_sale' columns!
-- this is because of the NULL values in 'final_sale' and the inconsistency in 'final_quantity'

-- check the ranges for numeric field
SELECT
    MIN(FINAL_SALE) AS MIN_SALE,
    AVG(FINAL_SALE) AS AVG_SALE,
    MAX(FINAL_SALE) AS MAX_SALE
FROM
    TRANSACTIONS;

SELECT
    *
FROM
    TRANSACTIONS
WHERE
    FINAL_SALE > 100
ORDER BY
    FINAL_SALE DESC;

-- check the consisteny within date fields
SELECT
    *
FROM
    TRANSACTIONS
WHERE
    SCAN_DATE < PURCHASE_DATE;
-- 94 records have 'scan_date' earlier than 'purchase_date' which cannot be correct since it is not possible to scan a receipt without having it
-- these values either should be dropped or further analyzed to understand how they should actually be

-- check the unexpected values for categorical fields
SELECT
    DISTINCT STORE_NAME
FROM
    TRANSACTIONS
ORDER BY
    STORE_NAME ASC;
-- between 952 distinct values I saw that there is a store called 'ALQI', not sure If this is an actual store or typo for 'ALDI'

SELECT
    *
FROM
    TRANSACTIONS
WHERE
    STORE_NAME IN ('ALDI', 'ALQI')
ORDER BY
    STORE_NAME DESC;
-- There is only one recipt with 'ALQI', this should be further discussed



-- DATA EXPLORATION - USERS TABLE

-- Quick view of data
SELECT
    *
FROM
    USERS
ORDER BY
    ID;

-- check the nulls
SELECT
    COUNT(*) AS TOTAL_ROWS, -- Total number of rows
    COUNT(*) - COUNT(ID) AS ID_NULLS, -- Subtracting the total rows to get the number of NULL values
    COUNT(*) - COUNT(CREATED_DATE) AS CREATED_DATE_NULLS,
    COUNT(*) - COUNT(BIRTH_DATE) AS BIRTH_DATE_NULLS,
    COUNT(*) - COUNT(STATE) AS STATE_NULLS,
    COUNT(*) - COUNT(LANGUAGE) AS LANGUAGE_NULLS,
    COUNT(*) - COUNT(GENDER) AS GENDER_NULLS
FROM
    USERS;
-- NULL values identified in the following fields:
-- 'BIRTH_DATE' - 3675
-- 'STATE' - 4812
-- 'LANGUAGE' - 30508
-- 'GENDER' - 5892

-- Check categorical variables consistency
SELECT
    DISTINCT STATE
FROM
    USERS
ORDER BY
    STATE;
-- checks out

SELECT
    DISTINCT LANGUAGE
FROM
    USERS
ORDER BY
    LANGUAGE;
-- checks out

SELECT
    DISTINCT GENDER
FROM
    USERS
ORDER BY
    GENDER;
-- some values can be grouped together as following:
-- male : "male"
-- female : "female"
-- non-binary : "non-binary", "Non-Binary"
-- transgender : "transgender"
-- other : "My gender isn't listed", "not_listed", "not_specified", "unknown"
-- prefer not to say : "Prefer not to say", "prefer_not_to_say"

UPDATE
    USERS
SET
    GENDER = 'non-binary'
WHERE
    GENDER = 'Non-Binary'
OR
    GENDER = 'non_binary';
    
UPDATE
    USERS
SET
    GENDER = 'other'
WHERE
    GENDER = 'My gender isn''t listed'
OR
    GENDER = 'not_listed'
OR
    GENDER = 'not_specified'
OR
    GENDER = 'unknown';

UPDATE
    USERS
SET
    GENDER = 'prefer not to say'
WHERE
    GENDER = 'Prefer not to say'
OR
    GENDER = 'prefer_not_to_say';

-- check the date fields
SELECT
    MIN(CREATED_DATE),
    MAX(CREATED_DATE),
    MIN(BIRTH_DATE),
    MAX(BIRTH_DATE)
FROM
    USERS;
-- Apparently someone was born in 1900 and still alive :)

SELECT
    BIRTH_DATE
FROM
    USERS
ORDER BY
    BIRTH_DATE;
-- An age range should be determined to validate the 'birth_date' field
-- For data reliability, I will delete any user who was born before 1908 considering, AS OF JANUARY 2025 the oldest human alive is about 117 years old

DELETE FROM
    USERS
WHERE YEAR(BIRTH_DATE) < 1908;

-- check for duplicates
SELECT
    ID,
    CREATED_DATE,
    BIRTH_DATE,
    STATE,
    LANGUAGE,
    GENDER,
    COUNT(*) AS COUNT
FROM
    USERS
GROUP BY
    ID,
    CREATED_DATE,
    BIRTH_DATE,
    STATE,
    LANGUAGE,
    GENDER
HAVING
    COUNT(*) > 1;
-- NO DUPLICATES

-- check if every value in 'ID' column is unique
SELECT
    ID,
    COUNT(*) AS COUNT
FROM
    USERS
GROUP BY
    ID
HAVING
    COUNT(*) > 1;
-- YES IT IS

-- Common rows between tables:

-- USERS - TRANSACTIONS
SELECT
    *
FROM
    USERS AS u
INNER JOIN
    TRANSACTIONS AS t
ON
    u.ID = t.USER_ID;
-- 258 RECORDS RETURNED

-- TRANSACTIONS- PRODUCTS
SELECT
    *
FROM
    PRODUCTS AS p
INNER JOIN
    TRANSACTIONS AS t
ON
    p.BARCODE = t.BARCODE;
-- 24.6K RECORDS RETURNED

-- USERS - TRANSACTIONS - PRODUCTS
SELECT
    *
FROM
    TRANSACTIONS AS t
INNER JOIN
    USERS AS u
ON
    u.ID = t.USER_ID
INNER JOIN
    PRODUCTS AS p
ON
    t.BARCODE = p.BARCODE;
-- 144 RECORDS RETURNED

-- Since the % of rows in common is low -especially between users and transactions- it will be hard to join these tables together to come up with an insight because there will not be enough data.

-- Personally I couldn't make sense of FINAL_QUANTITY since the values are not integer. Are these like weights of fruits and vegetables?
SELECT
    *
FROM
    TRANSACTIONS AS t
JOIN
    PRODUCTS AS p
ON
    t.BARCODE = p.BARCODE
WHERE
    (t.FINAL_QUANTITY % 0.25 )!= 0;

-- Also some values in FINAL_QUANTITY and FINAL_SALE are '0'. If there is not quantity or sale, how can this be a receipt?

SELECT
    DISTINCT FINAL_QUANTITY
FROM
    TRANSACTIONS
ORDER BY
    FINAL_QUANTITY;

SELECT
    DISTINCT FINAL_SALE
FROM
    TRANSACTIONS
ORDER BY
    FINAL_SALE;