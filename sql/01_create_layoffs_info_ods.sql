-- ============================================================
-- Project : Layoffs Data Cleaning
-- Layer   : ODS (Operational Data Store)
-- File    : 01_create_layoffs_info_ods.sql
-- Purpose :
--   1. Create ODS and DWD databases
--   2. Create ODS table and load raw CSV
--   3. Perform initial profiling for later cleaning
--
-- Notes:
--   - LOAD DATA LOCAL INFILE requires local_infile enabled on both
--     server and client sides.
--   - Replace the CSV path with your own local path.
--   - ODS layer keeps loose data types and is append-only,
--     so raw data remains traceable.
-- ============================================================

-- ============================================================
-- 1. Create databases
-- ============================================================

-- ODS: raw data layer
CREATE DATABASE IF NOT EXISTS layoff_ods 
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- DWD: cleaned detail layer
CREATE DATABASE IF NOT EXISTS layoff_dwd 
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- ============================================================
-- 2. Switch to ODS
-- ============================================================

USE layoff_ods;

-- Drop old table to make script re-runnable
DROP TABLE IF EXISTS layoffs_info_ods;

-- ============================================================
-- 3. Create ODS raw table
-- ------------------------------------------------------------
-- Design principles:
--   - Column names match the CSV header
--   - Use VARCHAR for all fields to avoid import failures
--   - Add auto-increment id for later deduplication
--   - Add created_at to record import time
--   - Table name ends with _ods to indicate its layer
-- ============================================================

CREATE TABLE IF NOT EXISTS layoffs_info_ods (
    id                      INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Auto-increment primary key',
    company                 VARCHAR(100) COMMENT 'Company name',
    location                VARCHAR(100) COMMENT 'Location',
    industry                VARCHAR(100) COMMENT 'Industry',
    total_laid_off          VARCHAR(50)  COMMENT 'Total laid off (raw text)',
    percentage_laid_off     VARCHAR(50)  COMMENT 'Percentage laid off (raw text)',
    `date`                  VARCHAR(50)  COMMENT 'Date (raw text)',
    stage                   VARCHAR(50)  COMMENT 'Funding stage',
    country                 VARCHAR(50)  COMMENT 'Country',
    funds_raised_millions   VARCHAR(50)  COMMENT 'Funds raised in millions (raw text)',
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Import time'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Raw layoff data table (ODS layer)';

-- ============================================================
-- 4. Load raw CSV data
-- ------------------------------------------------------------
-- Replace the path below with your local CSV file path.
-- Field delimiter : comma
-- Enclosed by     : double quote
-- Line delimiter  : \n
-- Skip 1 header row
-- ============================================================

LOAD DATA LOCAL INFILE '/path/to/your/Layoffs By Different Companies.csv'
INTO TABLE layoffs_info_ods
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(company, location, industry, total_laid_off, percentage_laid_off,
 `date`, stage, country, funds_raised_millions);

-- ============================================================
-- 5. Initial profiling
-- ============================================================

-- Preview imported rows
SELECT * FROM layoffs_info_ods;

-- Count records where filed is empty string
SELECT COUNT(*) FROM layoffs_info_ods WHERE stage = '';

-- Total row count
SELECT COUNT(*) FROM layoffs_info_ods;

-- ============================================================
-- 6. Field length profiling
-- ------------------------------------------------------------
-- Purpose: Find the actual maximum character length of each field,
--          to support later ALTER TABLE statements that tighten
--          column lengths.
-- ============================================================

SELECT 
    MAX(CHAR_LENGTH(company))               AS company_max,
    MAX(CHAR_LENGTH(location))              AS location_max,
    MAX(CHAR_LENGTH(industry))              AS industry_max,
    MAX(CHAR_LENGTH(stage))                 AS stage_max,
    MAX(CHAR_LENGTH(country))               AS country_max,
    MAX(CHAR_LENGTH(total_laid_off))        AS total_laid_off_max,
    MAX(CHAR_LENGTH(percentage_laid_off))   AS percentage_laid_off_max,
    MAX(CHAR_LENGTH(funds_raised_millions)) AS funds_raised_millions_max,
    MAX(CHAR_LENGTH(`date`))                AS date_max
FROM layoffs_info_ods;

-- ============================================================
-- Next steps (not included in this script):
--   1. Create DWD table
--   2. Clean: TRIM, null handling, date normalization, deduplication
--   3. Type conversion: VARCHAR -> INT / DECIMAL / DATE
--   4. Add primary key and indexes
--   5. Validate and document
-- ============================================================