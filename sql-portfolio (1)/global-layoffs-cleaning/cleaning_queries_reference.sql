-- ============================================================
-- Global Layoffs Data Cleaning — Reference Query Log
-- NOTE: This is a reconstructed reference based on project notes.
-- Replace/merge with your own saved .sql file from MySQL Workbench,
-- which contains your original, exact queries.
-- ============================================================

-- 1. Create a staging table so raw data is never modified directly
CREATE TABLE layoffs_staging LIKE layoffs;
INSERT INTO layoffs_staging SELECT * FROM layoffs;

-- 2. Identify duplicates using ROW_NUMBER + PARTITION BY
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, `date`, stage, country, funds_raised
    ) AS row_num
FROM layoffs_staging;

-- 2b. Same logic via CTE, to validate results before deleting
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off,
                         percentage_laid_off, `date`, stage, country, funds_raised
        ) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;

-- 2c. Create a second staging table including row_num, then delete duplicates
CREATE TABLE layoffs_staging2 LIKE layoffs_staging;
ALTER TABLE layoffs_staging2 ADD COLUMN row_num INT;

INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, `date`, stage, country, funds_raised
    ) AS row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging2 WHERE row_num > 1;

-- 3. Standardize data
UPDATE layoffs_staging2 SET company = TRIM(company);

-- Fix stray punctuation, e.g. "United States." -> "United States"
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Correct known spelling inconsistencies (example pattern)
-- UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

-- 4. Convert date from text to DATE
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 5. Identify and fill nulls/blanks using related records (self-join on company)
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- 6. Remove the temporary helper column used only for deduplication
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final clean dataset: layoffs_staging2
SELECT * FROM layoffs_staging2;
