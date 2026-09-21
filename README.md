# Layoffs Data Cleaning Project

## Project Overview

This project demonstrates an end-to-end SQL data cleaning workflow for a real-world layoffs dataset, with a focus on the type of data preparation commonly performed by a Data Analyst before downstream analysis and reporting.

The project starts with raw CSV data containing company layoff records from around the world. Raw datasets often contain practical data-quality issues such as missing values, inconsistent formatting, extra whitespace, inconsistent date representations, duplicate records, and fields stored as text even when they are intended to represent numeric or date values.

To address these issues, the project uses a simple **ODS → DWD** data-layering approach:

- **ODS (Operational Data Store)** preserves the raw imported data and provides a stable source for cleaning.
- **DWD (Data Warehouse Detail)** contains cleaned, standardized, deduplicated, and analysis-ready records.
- The cleaned DWD layer can then serve as the foundation for downstream aggregation, reporting, visualization, or BI analysis.

Rather than performing isolated SQL transformations, this project organizes the cleaning process as a repeatable workflow:

**raw data ingestion → data profiling → text normalization → missing-value handling → date standardization → deduplication → data type conversion → indexing → data-quality validation**

The goal is not only to produce a clean table, but also to demonstrate how SQL can be used systematically to turn messy source data into a structured dataset that is easier and safer to analyze.

## Project Purpose

The main goals are:

1. **Understand data layering**  
   Use ODS (Operational Data Store) and DWD (Data Warehouse Detail) layers to separate raw source data from cleaned data and make the transformation process easier to trace.

2. **Practice a complete SQL data cleaning workflow**  
   Apply common data-cleaning techniques including data profiling, whitespace removal, null handling, date normalization, deduplication, data type conversion, schema refinement, and index creation.

3. **Handle common real-world data-quality problems**  
   Work with issues that frequently appear in raw datasets, such as empty strings, missing values, inconsistent date formats, duplicate records, and numeric fields initially stored as `VARCHAR`.

4. **Build reproducible cleaning scripts**  
   Organize the transformation process into SQL scripts that can be rerun from the raw ODS layer, making the workflow easier to maintain, review, and adapt to similar datasets.

5. **Prepare data for downstream analysis**  
   Convert the cleaned DWD table into a structured, analysis-ready dataset that can support subsequent SQL analysis, aggregation, reporting, visualization, or BI dashboards.

6. **Demonstrate practical Data Analyst skills**  
   Showcase the ability to inspect raw data, identify data-quality issues, select appropriate cleaning strategies, transform data with SQL, and validate the final dataset rather than simply writing isolated SQL queries.

## Data Cleaning Workflow

The overall workflow is:

```text
Raw CSV
   ↓
ODS Layer
   ↓
Data Profiling
   ↓
TRIM / Text Normalization
   ↓
Missing-Value Handling
   ↓
Date Standardization
   ↓
Deduplication
   ↓
Data Type Conversion
   ↓
Schema Refinement
   ↓
Indexes
   ↓
Data Quality Validation
   ↓
DWD Analysis-Ready Table
```

## Key Cleaning Tasks

### 1. Raw Data Ingestion

The raw CSV dataset is loaded into the ODS layer while preserving the original field structure. This provides a raw-data baseline that can be used to reproduce the cleaning process.

### 2. Text Normalization

Text fields are standardized with `TRIM()` to remove unnecessary leading and trailing whitespace.

### 3. Missing-Value Handling

Missing values are handled according to the meaning of each field:

- Categorical fields such as `industry`, `stage`, and `country` use `Unknown` where appropriate.
- Numeric and date fields preserve missing information as `NULL` rather than incorrectly converting unknown values into zero or another arbitrary value.

### 4. Date Standardization

Different date representations are converted into a consistent `YYYY-MM-DD` format before the field is ultimately stored as the MySQL `DATE` type.

### 5. Deduplication

Duplicate records are identified using a business-oriented key consisting of:

```text
company + date + total_laid_off + country
```

`ROW_NUMBER()` is used to rank duplicate records, keeping the latest imported record based on `created_at`, with `id` used as a secondary ordering criterion.

### 6. Data Type Conversion

Fields that are initially stored as strings are converted to appropriate database types:

- `total_laid_off` → `INT`
- `percentage_laid_off` → `DECIMAL`
- `funds_raised_millions` → `DECIMAL`
- `date` → `DATE`

This makes the cleaned data more reliable for calculations, filtering, aggregation, and downstream analysis.

### 7. Schema Refinement and Indexing

After cleaning and type conversion, the DWD table is refined with appropriate field definitions, comments, a primary key, and indexes on frequently queried fields such as company, industry, date, and country.


## Dataset

- **Dataset**: Layoffs By Different Companies.csv
- **Content**: Layoff records from companies worldwide, including company name, location, industry, total laid off, percentage laid off, date, funding stage, country, and funds raised.
- **Raw format**: CSV, with issues such as nulls, extra spaces, inconsistent date formats, and duplicate records.

## Tech Stack

- **Database**: MySQL 8.0+
- **Client**: DBeaver
- **Language**: SQL
- **Version Control**: Git / GitHub

## Directory Structure

```text
layoff-data-cleaning/
├── sql/
│   ├── 01_create_layoffs_info_ods.sql          -- Create ODS database, table, and load raw CSV
│   └── 02_layoffs_info_dwd_data_cleaning.sql   -- Copy to DWD, clean, deduplicate, and convert types
├── data/
│   └── Layoffs By Different Companies.csv      -- Raw data (not uploaded)
├── README.md
└── .gitignore
```

## Skills Demonstrated

- SQL data cleaning
- Data profiling and quality assessment
- ODS / DWD data-layering concepts
- `TRIM()`, `NULLIF()`, `COALESCE()`, and `CASE`
- Regular expressions for format validation
- Date parsing and standardization
- Window functions and deduplication with `ROW_NUMBER()`
- Data type conversion
- Schema design and refinement
- Primary keys and indexes
- Data-quality validation
- Reproducible SQL workflows
