# Global Layoffs Data Cleaning (MySQL)

## Overview
Cleaned a raw dataset on global layoffs (provided, ~2,000+ rows, 9 columns, no primary
key) using MySQL, transforming it into an analysis-ready dataset.

## Issues in the Raw Data
- Duplicate records
- Missing values and nulls
- Inconsistent spelling and formatting (e.g., stray punctuation in country names)
- Untrimmed text fields (leading/trailing whitespace)
- Date field stored as text instead of DATE
- An extra helper column not needed in the final dataset

## Process
1. Created a staging table and inserted the raw data, to avoid modifying the original
2. Identified duplicates using `ROW_NUMBER()` with `PARTITION BY`, cross-checked with a
   CTE-based approach before deleting
3. Standardized text data — trimmed whitespace, corrected spelling, removed stray
   punctuation (e.g., "United States.")
4. Converted the date column from text to `DATE` using `STR_TO_DATE` and `ALTER TABLE`
5. Identified nulls/blanks and filled them where a related, non-null record existed for
   the same entity (via self-join)
6. Removed the temporary helper column used only for the cleaning process

## Result
A clean, deduplicated, correctly typed dataset ready for downstream analysis.

## Files
- [`cleaning_queries_reference.sql`](./cleaning_queries_reference.sql) — full query log
- [`Global_Layoffs_Project_Summary.docx`](./Global_Layoffs_Project_Summary.docx) — written summary of the project
