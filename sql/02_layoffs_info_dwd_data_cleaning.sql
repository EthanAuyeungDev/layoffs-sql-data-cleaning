-- ============================================================
-- Project : Layoffs Data Cleaning
-- Layer   : DWD (Data Warehouse Detail)
-- File    : 02_layoffs_info_dwd_data_cleaning.sql
-- Purpose :
--   1. Copy raw data from ODS to DWD
--   2. Clean text columns (TRIM, null handling)
--   3. Normalize date and numeric formats
--   4. Deduplicate records
--   5. Convert data types (ALTER TABLE MODIFY)
--   6. Add indexes and validate results
-- ============================================================

USE layoff_dwd;

-- ============================================================
-- 1. Copy ODS -> DWD
-- ============================================================

DROP TABLE IF EXISTS layoffs_info_dwd;

CREATE TABLE layoffs_info_dwd LIKE layoff_ods.layoffs_info_ods;

INSERT INTO layoffs_info_dwd
SELECT * FROM layoff_ods.layoffs_info_ods;

-- Preview data
SELECT * FROM layoff_dwd.layoffs_info_dwd LIMIT 100;

-- Total row count in ODS
SELECT COUNT(*) FROM layoff_ods.layoffs_info_ods;

-- ============================================================
-- 2. Data profiling
-- ============================================================

-- Count NULL values per column
SELECT 
    SUM(company IS NULL)               AS company_null,
    SUM(location IS NULL)              AS location_null,
    SUM(industry IS NULL)              AS industry_null,
    SUM(total_laid_off IS NULL)        AS total_laid_off_null,
    SUM(percentage_laid_off IS NULL)   AS percentage_laid_off_null,
    SUM(`date` IS NULL)                AS date_null,
    SUM(country IS NULL)               AS country_null,
    SUM(funds_raised_millions IS NULL) AS funds_raised_millions_null
FROM layoff_dwd.layoffs_info_dwd;

-- Check rows with leading/trailing spaces
SELECT company FROM layoff_dwd.layoffs_info_dwd WHERE company != TRIM(company);
SELECT location FROM layoff_dwd.layoffs_info_dwd WHERE location != TRIM(location);
SELECT industry FROM layoff_dwd.layoffs_info_dwd WHERE industry != TRIM(industry);
SELECT stage FROM layoff_dwd.layoffs_info_dwd WHERE stage != TRIM(stage);
SELECT country FROM layoff_dwd.layoffs_info_dwd WHERE country != TRIM(country);
SELECT total_laid_off FROM layoff_dwd.layoffs_info_dwd WHERE total_laid_off != TRIM(total_laid_off);
SELECT percentage_laid_off FROM layoff_dwd.layoffs_info_dwd WHERE percentage_laid_off != TRIM(percentage_laid_off);
SELECT funds_raised_millions FROM layoff_dwd.layoffs_info_dwd WHERE funds_raised_millions != TRIM(funds_raised_millions);
SELECT `date` FROM layoff_dwd.layoffs_info_dwd WHERE `date` != TRIM(`date`);

-- ============================================================
-- 3. Trim all text columns
-- ============================================================

UPDATE layoffs_info_dwd SET company = TRIM(company);
UPDATE layoffs_info_dwd SET location = TRIM(location);
UPDATE layoffs_info_dwd SET industry = TRIM(industry);
UPDATE layoffs_info_dwd SET total_laid_off = TRIM(total_laid_off);
UPDATE layoffs_info_dwd SET percentage_laid_off = TRIM(percentage_laid_off);
UPDATE layoffs_info_dwd SET `date` = TRIM(`date`);
UPDATE layoffs_info_dwd SET stage = TRIM(stage);
UPDATE layoffs_info_dwd SET country = TRIM(country);
UPDATE layoffs_info_dwd SET funds_raised_millions = TRIM(funds_raised_millions);

-- Check max length after trimming
SELECT 
    MAX(LENGTH(company))  AS company_max,
    MAX(LENGTH(location)) AS location_max,
    MAX(LENGTH(industry)) AS industry_max,
    MAX(LENGTH(stage))    AS stage_max,
    MAX(LENGTH(country))  AS country_max
FROM layoffs_info_dwd;

-- ============================================================
-- 4. Inspect NULL and empty string values
-- ============================================================

-- Check NULL values
SELECT * FROM layoffs_info_dwd WHERE company IS NULL;
SELECT * FROM layoffs_info_dwd WHERE location IS NULL;
SELECT * FROM layoffs_info_dwd WHERE industry IS NULL;
SELECT * FROM layoffs_info_dwd WHERE total_laid_off IS NULL;
SELECT * FROM layoffs_info_dwd WHERE percentage_laid_off IS NULL;
SELECT * FROM layoffs_info_dwd WHERE `date` IS NULL;
SELECT * FROM layoffs_info_dwd WHERE stage IS NULL;
SELECT * FROM layoffs_info_dwd WHERE country IS NULL;
SELECT * FROM layoffs_info_dwd WHERE funds_raised_millions IS NULL;

-- Check empty string values
SELECT * FROM layoffs_info_dwd WHERE company = '';
SELECT * FROM layoffs_info_dwd WHERE location = '';
SELECT * FROM layoffs_info_dwd WHERE industry = '';
SELECT * FROM layoffs_info_dwd WHERE total_laid_off = '';
SELECT * FROM layoffs_info_dwd WHERE percentage_laid_off = '';
SELECT * FROM layoffs_info_dwd WHERE `date` = '';
SELECT * FROM layoffs_info_dwd WHERE stage = '';
SELECT * FROM layoffs_info_dwd WHERE country = '';
SELECT * FROM layoffs_info_dwd WHERE funds_raised_millions = '';

-- ============================================================
-- 5. Handle empty strings and NULLs
-- ============================================================

-- Text columns: replace '' and NULL with 'Unknown'
UPDATE layoffs_info_dwd SET industry = COALESCE(NULLIF(industry, ''), 'Unknown');
UPDATE layoffs_info_dwd SET stage = COALESCE(NULLIF(stage, ''), 'Unknown');
UPDATE layoffs_info_dwd SET country = COALESCE(NULLIF(country, ''), 'Unknown');

-- Numeric and date columns: convert '' to NULL
UPDATE layoffs_info_dwd SET total_laid_off = NULLIF(total_laid_off, '');
UPDATE layoffs_info_dwd SET percentage_laid_off = NULLIF(percentage_laid_off, '');
UPDATE layoffs_info_dwd SET `date` = NULLIF(`date`, '');
UPDATE layoffs_info_dwd SET funds_raised_millions = NULLIF(funds_raised_millions, '');

-- ============================================================
-- 6. Normalize date format
-- ============================================================

-- Explore distinct date formats
SELECT DISTINCT `date`
FROM layoffs_info_dwd
WHERE `date` IS NOT NULL
ORDER BY `date`
LIMIT 100;

-- Convert all date formats to YYYY-MM-DD
UPDATE layoffs_info_dwd
SET `date` = CASE
    WHEN `date` LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(`date`, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN `date` LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(`date`, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END
WHERE `date` IS NOT NULL;

-- ============================================================
-- 7. Deduplicate records
-- ============================================================

-- Explore duplicates: expected 7 rows to delete
WITH rk_info AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY company, `date`, total_laid_off, country 
            ORDER BY id DESC
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY company, `date`, total_laid_off, country
        ) AS total_num
    FROM layoff_dwd.layoffs_info_dwd
)
SELECT COUNT(*)
FROM rk_info
WHERE rn > 1
ORDER BY total_num DESC;

-- Delete duplicate rows
DELETE t
FROM layoff_dwd.layoffs_info_dwd t
JOIN (
    SELECT id
    FROM (
        SELECT 
            id,
            ROW_NUMBER() OVER (
                PARTITION BY company, `date`, total_laid_off, country 
                ORDER BY created_at, id DESC
            ) AS rk
        FROM layoff_dwd.layoffs_info_dwd
    ) AS rk_info
    WHERE rk_info.rk > 1
) d
ON t.id = d.id;

-- Preview after deduplication
SELECT * FROM layoff_dwd.layoffs_info_dwd ORDER BY company, location;

-- Note: IDs may have gaps after deletion, but they remain unique
SELECT MIN(id), MAX(id), COUNT(*) FROM layoff_dwd.layoffs_info_dwd;

-- ============================================================
-- 8. Modify table definition (data type conversion)
-- ============================================================

ALTER TABLE layoff_dwd.layoffs_info_dwd
    -- Text columns: keep VARCHAR but tighten length
    MODIFY company VARCHAR(70) NOT NULL COMMENT 'Company name',
    MODIFY location VARCHAR(50) COMMENT 'Location',
    MODIFY industry VARCHAR(50) COMMENT 'Industry',
    MODIFY stage VARCHAR(50) COMMENT 'Funding stage',
    MODIFY country VARCHAR(50) COMMENT 'Country',
    -- Numeric columns: convert to numbers
    MODIFY total_laid_off INT COMMENT 'Total laid off',
    MODIFY percentage_laid_off DECIMAL(5,4) COMMENT 'Percentage laid off',
    MODIFY funds_raised_millions DECIMAL(10,2) COMMENT 'Funds raised in millions',
    -- Date column: convert to DATE type
    MODIFY `date` DATE COMMENT 'Layoff date';

-- This column failed to convert due to 'NULL\r' values, not real NULLs
ALTER TABLE layoff_dwd.layoffs_info_dwd
    MODIFY funds_raised_millions DECIMAL(10,2) COMMENT 'Funds raised in millions';

-- Inspect the problematic values
SELECT
    funds_raised_millions,
    LENGTH(funds_raised_millions) AS len,
    HEX(funds_raised_millions) AS hex_value
FROM layoff_dwd.layoffs_info_dwd
WHERE funds_raised_millions LIKE '%NULL%';

-- Convert those values to real NULL
UPDATE layoff_dwd.layoffs_info_dwd
SET funds_raised_millions = NULL
WHERE funds_raised_millions LIKE '%NULL%';

-- ============================================================
-- 9. Add indexes
-- ============================================================

CREATE INDEX idx_dwd_layoffs_company  ON layoff_dwd.layoffs_info_dwd (company);
CREATE INDEX idx_dwd_layoffs_date     ON layoff_dwd.layoffs_info_dwd (`date`);
CREATE INDEX idx_dwd_layoffs_country  ON layoff_dwd.layoffs_info_dwd (country);
CREATE INDEX idx_dwd_layoffs_industry ON layoff_dwd.layoffs_info_dwd (industry);

-- ============================================================
-- 10. Validation
-- ============================================================

-- Row count comparison
SELECT 
    (SELECT COUNT(*) FROM layoff_ods.layoffs_info_ods) AS ods_rows,
    (SELECT COUNT(*) FROM layoff_dwd.layoffs_info_dwd) AS dwd_rows;

-- Null rate for key columns
SELECT 
    SUM(company IS NULL)         AS company_null,
    SUM(`date` IS NULL)          AS date_null,
    SUM(total_laid_off IS NULL)  AS total_laid_off_null
FROM layoff_dwd.layoffs_info_dwd;

-- Numeric and date ranges
SELECT 
    MIN(total_laid_off)      AS min_laid,
    MAX(total_laid_off)      AS max_laid,
    MIN(percentage_laid_off) AS min_pct,
    MAX(percentage_laid_off) AS max_pct,
    MIN(`date`)              AS min_date,
    MAX(`date`)              AS max_date
FROM layoff_dwd.layoffs_info_dwd;