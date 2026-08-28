-- Data cleaning
SELECT * FROM world_layoffs.layoffs;
-- create a table for the staging
CREATE TABLE layoffs_staging
LIKE world_layoffs.layoffs;

select*
from layoffs_staging;

-- insert into staging table
INSERT layoffs_staging
SELECT*
FROM layoffs;

-- find and remove the duplicates(we partion with row number)
SELECT *,
ROW_NUMBER() OVER (
        PARTITION BY lay2.company, lay2.location, lay2.industry, 
        lay2.total_laid_off, lay2.percentage_laid_off, lay2.date, 
        lay2.stage, lay2.country, lay2.funds_raised_millions
        ORDER BY lay2.company
    ) AS row_num
    from layoffs_staging as lay2;
    -- find and remove the duplicates(we cte the row number)
    with lay2_cte AS
    (
    SELECT *,
ROW_NUMBER() OVER (
        PARTITION BY lay2.company, lay2.location, lay2.industry, 
        lay2.total_laid_off, lay2.percentage_laid_off, lay2.date, 
        lay2.stage, lay2.country, lay2.funds_raised_millions
        ORDER BY lay2.company
    ) AS row_num
    from layoffs_staging as lay2
    )
    SELECT *
    FROM lay2_cte
    where row_num > 1;

SELECT *
FROM layoffs_staging
where company = 'casper';
 -- find and remove the duplicates(we create another table and delete the duplicates)
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM world_layoffs.layoffs_staging2;

INSERT layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
        PARTITION BY lay2.company, lay2.location, lay2.industry, 
        lay2.total_laid_off, lay2.percentage_laid_off, lay2.date, 
        lay2.stage, lay2.country, lay2.funds_raised_millions
        ORDER BY lay2.company
    ) AS row_num
    from layoffs_staging as lay2;
    
DELETE 
FROM layoffs_staging2
where row_num > 1;
    
SELECT * 
FROM layoffs_staging2;

-- Standardizing data

SELECT company, trim(company)
FROM layoffs_staging2;
 -- update the column(company) to the trim
update layoffs_staging2
set company = trim(company);
-- correct spelling
SELECT distinct industry
FROM layoffs_staging2
where industry like 'crypto%';

UPDATE layoffs_staging2
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';

SELECT distinct industry
FROM layoffs_staging2
order by 1;
-- next cloumn 
SELECT distinct location 
FROM layoffs_staging2
 where location like '%dorf';

UPDATE layoffs_staging2
SET location = 'Düsseldorf'
WHERE location LIKE '%dorf';
-- next country
SELECT*
FROM layoffs_staging2;

SELECT country
FROM layoffs_staging2
order by 1;

-- the united states one of them has a period(.) which need to be removed with trim 
SELECT Distinct trim(trailing'.'from country), country
FROM layoffs_staging2
order by 1;

UPDATE layoffs_staging2
SET country = trim(trailing'.'from country)
WHERE country LIKE 'united states%';

-- change date from text to date
SELECT date, 
str_to_date(date, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET date = str_to_date(date, '%m/%d/%Y');

SELECT date
FROM layoffs_staging2;
-- now alter data type of date from text to DATE
alter table layoffs_staging2
modify date DATE;

-- remove nulls and blanks 
SELECT *
FROM layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null
order by company asc;
 -- check for the nulls/blank and th not nulls with join
select distinct  t1.company, t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

SELECT *
FROM layoffs_staging2
WHERE company like 'bally%';
-- next we update and fill the nulls and blanks to be filled with their reliative data

update layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null 
and t2.industry is not null;

update layoffs_staging2
set industry = null
where industry = '';

-- we delete the irrelivant column
delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- remove the extra column(row_num) to the table
alter table layoffs_staging2
drop column row_num;

-- Exploratory Data Anaysis
select company, max(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

select max(total_laid_off), max(date), min(date)
from layoffs_staging2;

select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

select country, total_laid_off
from layoffs_staging2
order by country desc;



