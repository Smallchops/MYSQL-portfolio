SELECT * FROM insurance_claims.claims;
-- complete table with customers with and without claims and policy
CREATE TABLE insurance_claims.claims_comp_report AS
SELECT 
    c.customer_id, c.customer_name, c.gender, c.age,
    c.region, c.signup_date, p.policy_id, p.policy_type,
    p.premium_amount, p.start_date AS policy_start_date,
    p.end_date AS policy_end_date, cl.claim_id, cl.claim_type,
    cl.claim_date, cl.amount_claimed, cl.payout_amount, cl.status, 
    cl.fraud_flag
FROM insurance_claims.customers c
LEFT JOIN insurance_claims.policies p 
    ON c.customer_id = p.customer_id
LEFT JOIN insurance_claims.claims cl 
    ON p.policy_id = cl.policy_id;

-- complete table with customers without claims and policy
CREATE TABLE insurance_claims.claims_full_report AS
SELECT 
    c1.customer_id, c1.customer_name, c1.gender, c1.age,
    c1.region, c1.signup_date, p.policy_id, p.policy_type,
    p.premium_amount, p.start_date,
    p.end_date, c2.claim_id, c2.claim_type,
    c2.claim_date, c2.amount_claimed, 
    c2.payout_amount, c2.status, c2.fraud_flag
FROM insurance_claims.customers as c1
JOIN insurance_claims.policies p 
    ON c1.customer_id = p.customer_id
JOIN insurance_claims.claims as c2 
    ON p.policy_id = c2.policy_id
    order by customer_id asc;
    
    SELECT 
    (SELECT COUNT(*) FROM insurance_claims.claims_comp_report) AS total_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM insurance_claims.claims_full_report) AS customers_with_claims,
    (SELECT COUNT(*) FROM insurance_claims.claims_comp_report) - 
    (SELECT COUNT(DISTINCT customer_id) FROM insurance_claims.claims_full_report) AS customers_without_claims;
-- remove duplicates 
select *,
row_number() over(
partition by c_report.customer_id, c_report.customer_name, c_report.gender, c_report.age,
    c_report.region, c_report.signup_date, c_report.policy_id, c_report.policy_type,
    c_report.premium_amount, c_report.start_date,
    c_report.end_date, c_report.claim_id, c_report.claim_type,
    c_report.claim_date, c_report.amount_claimed, 
    c_report.payout_amount, c_report.status, c_report.fraud_flag
) as row_num
from claims_full_report c_report;

-- partition for the claim complete report
select *,
row_number() over(
partition by  comp_report.customer_id, comp_report.customer_name, 
	comp_report.gender, comp_report.age,comp_report.region, 
    comp_report.signup_date, comp_report.policy_id, 
    comp_report.policy_type, comp_report.premium_amount, 
    comp_report.policy_start_date, comp_report.policy_end_date, 
    comp_report.claim_id, comp_report.claim_type,
    comp_report.claim_date, comp_report.amount_claimed, 
    comp_report.payout_amount, comp_report.status, comp_report.fraud_flag
) as row_num
from claims_comp_report comp_report;

with comp_report_cte AS
(
select *,
row_number() over(
partition by  comp_report.customer_id, comp_report.customer_name, 
	comp_report.gender, comp_report.age,comp_report.region, 
    comp_report.signup_date, comp_report.policy_id, 
    comp_report.policy_type, comp_report.premium_amount, 
    comp_report.policy_start_date, comp_report.policy_end_date, 
    comp_report.claim_id, comp_report.claim_type,
    comp_report.claim_date, comp_report.amount_claimed, 
    comp_report.payout_amount, comp_report.status, comp_report.fraud_flag
) as row_num
from claims_comp_report comp_report
)
select * 
from comp_report_cte
where row_num > 1;

CREATE TABLE `claims_full_report2` (
  `customer_id` int DEFAULT NULL,
  `customer_name` text,
  `gender` text,
  `age` int DEFAULT NULL,
  `region` text,
  `signup_date` text,
  `policy_id` int DEFAULT NULL,
  `policy_type` text,
  `premium_amount` double DEFAULT NULL,
  `start_date` text,
  `end_date` text,
  `claim_id` int DEFAULT NULL,
  `claim_type` text,
  `claim_date` text,
  `amount_claimed` double DEFAULT NULL,
  `payout_amount` double DEFAULT NULL,
  `status` text,
  `fraud_flag` text,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert claims_full_report2
select *,
row_number() over(
partition by c_report.customer_id, c_report.customer_name, c_report.gender, c_report.age,
    c_report.region, c_report.signup_date, c_report.policy_id, c_report.policy_type,
    c_report.premium_amount, c_report.start_date,
    c_report.end_date, c_report.claim_id, c_report.claim_type,
    c_report.claim_date, c_report.amount_claimed, 
    c_report.payout_amount, c_report.status, c_report.fraud_flag
) as row_num
from claims_full_report c_report;

select *
from claims_full_report2
where customer_name like 'Alison%';

delete
from claims_full_report2
where row_num > 1;

CREATE TABLE `claims_comp_report2` (
  `customer_id` int DEFAULT NULL,
  `customer_name` text,
  `gender` text,
  `age` int DEFAULT NULL,
  `region` text,
  `signup_date` text,
  `policy_id` int DEFAULT NULL,
  `policy_type` text,
  `premium_amount` double DEFAULT NULL,
  `policy_start_date` text,
  `policy_end_date` text,
  `claim_id` int DEFAULT NULL,
  `claim_type` text,
  `claim_date` text,
  `amount_claimed` double DEFAULT NULL,
  `payout_amount` double DEFAULT NULL,
  `status` text,
  `fraud_flag` text,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert claims_comp_report2
select *,
row_number() over(
partition by  comp_report.customer_id, comp_report.customer_name, 
	comp_report.gender, comp_report.age,comp_report.region, 
    comp_report.signup_date, comp_report.policy_id, 
    comp_report.policy_type, comp_report.premium_amount, 
    comp_report.policy_start_date, comp_report.policy_end_date, 
    comp_report.claim_id, comp_report.claim_type,
    comp_report.claim_date, comp_report.amount_claimed, 
    comp_report.payout_amount, comp_report.status, comp_report.fraud_flag
) as row_num
from claims_comp_report comp_report;

delete
from claims_comp_report2
where row_num > 1;

-- next standardization
select *
from claims_full_report2;

select distinct customer_id, customer_name
from claims_comp_report2;

update claims_full_report2
set customer_name = "Phillip O'Brien"
 where customer_name like 'phillp%';

UPDATE claims_full_report2
SET customer_name = TRIM(
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(customer_name, 'Dr. ', ''),
            'Mrs. ', ''),
        'Mr. ', ''),
    'Ms. ', '')
)
WHERE customer_name LIKE 'Dr. %'
   OR customer_name LIKE 'Mrs. %'
   OR customer_name LIKE 'Mr. %'
   OR customer_name LIKE 'Ms. %';
   
SELECT customer_name FROM insurance_claims.claims_comp_report2
WHERE customer_name LIKE '%DDS%' OR customer_name LIKE '%MD%' 
   OR customer_name LIKE '%DVM%' OR customer_name LIKE '%Jr.%';

select *
from claims_comp_report2;
select *
from claims_full_report2
where customer_id = 2;

SELECT 
    customer_id,
    customer_name,
    COUNT(DISTINCT policy_id) AS num_policies,
    COUNT(DISTINCT claim_id) AS num_claims,
    max(distinct policy_id) as max_policy,
    max(distinct claim_id) as max_claims
FROM claims_full_report2
GROUP BY customer_id, customer_name
ORDER BY 1 asc;

SELECT 
    distinct gender,
    COUNT(gender)
FROM claims_comp_report2
where policy_id is null
and claim_id is null
GROUP BY gender;

SELECT 
    gender,
    COUNT(DISTINCT policy_id) AS num_policies,
    COUNT(DISTINCT claim_id) AS num_claims
FROM claims_full_report2
GROUP BY gender
ORDER BY 1 asc;
-- numbers of total, with and without claims
SELECT 
    (SELECT COUNT(*) FROM insurance_claims.claims_comp_report2) AS total_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM insurance_claims.claims_full_report2) AS customers_with_claims,
    (SELECT COUNT(*) FROM insurance_claims.claims_comp_report2) - 
    (SELECT COUNT(DISTINCT customer_id) FROM insurance_claims.claims_full_report2) AS customers_without_claims;  
SELECT COUNT(DISTINCT customer_id) FROM insurance_claims.claims_full_report2;

SELECT 
    gender,
    COUNT(DISTINCT policy_id) AS num_policies,
    COUNT(DISTINCT claim_id) AS num_claims,
    ROUND(COUNT(DISTINCT claim_id) / COUNT(DISTINCT policy_id), 2) AS claims_per_policy
FROM claims_full_report2
GROUP BY gender
ORDER BY claims_per_policy DESC;

select *
from claims_comp_report2;

select distinct policy_type, claim_type
from claims_full_report2
order by claim_type;   

update claims_full_report2
set claim_type = trim(claim_type);

select *
from claims_full_report2
;   

-- counted the amount of approved rejected,uder review, and pending
select count(*)
from claims_full_report2
where status like 'approve%';
select *
from claims_full_report2
where status like 'approv%';
-- standardize status
select distinct payout_amount, status
from claims_full_report2
where status like 'under%'
or status like 'pending%'
or status like 'reject%';

update claims_full_report2
set status = 'Under Review'
where status like 'under%';

-- counting the policy types we have: Travel, Health, Home, Life, and Auto.
select distinct policy_type
from claims_full_report2;

select *
from claims_full_report2
where policy_type like 'home%';

select count(*)
from claims_full_report2
where policy_type like 'home%';

select count(*)
from claims_full_report2
where policy_type like 'home%'
and claim_type like 'fire%';

SELECT claim_type, COUNT(*) AS total_claims
FROM claims_full_report2
WHERE policy_type LIKE 'home%'
GROUP BY claim_type
ORDER BY total_claims DESC;

select *
from claims_full_report2;

-- now alter data type of all date from text to DATE
alter table claims_full_report2
modify column claim_date DATE;

select *
from claims_full_report2
where customer_id;

select customer_id, customer_name, amount_claimed, payout_amount,
sum(payout_amount) over(partition by gender) as Total_payout
from claims_full_report2
where customer_id = 3;
-- total unresloved claim
SELECT
    status,
    COUNT(*) AS num_claims,
    SUM(amount_claimed) AS total_claimed_pending_decision
FROM claims_full_report2
WHERE status IN ('Pending', 'Under Review')
GROUP BY status;

-- total shortfall(claimed asked for and didnt recieved)
SELECT
    SUM(amount_claimed) AS total_claimed,
    SUM(payout_amount) AS total_paid_out,
    SUM(amount_claimed) - SUM(payout_amount) AS total_shortfall
FROM claims_full_report2;

-- analysing fraud flag
select count(distinct customer_id)
from claims_full_report2
where fraud_flag like'yes%'
and status like 'approve%';

select count(*)
from claims_full_report2
where fraud_flag like'yes%';

SELECT
    COUNT(DISTINCT claim_id) AS total_claims,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' THEN claim_id END) AS total_flagged,
    ROUND(
        COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' THEN claim_id END) * 100.0 
        / COUNT(DISTINCT claim_id), 2
    ) AS pct_flagged,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' AND status = 'Approved' THEN claim_id END) AS flagged_but_approved
FROM claims_full_report2;

SELECT
    policy_type,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' THEN claim_id END) AS flagged_claims,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' AND status = 'Approved' THEN claim_id END) AS flagged_and_approved
FROM claims_full_report2
GROUP BY policy_type
ORDER BY flagged_claims DESC;

select *
from claims_full_report2;

SELECT *
FROM claims_full_report2
WHERE fraud_flag = 'Yes'
  AND status = 'Approved'
ORDER BY payout_amount DESC
LIMIT 1;

SELECT
    policy_type,
    claim_type,
    MAX(payout_amount) AS max_payout_flagged_approved,
    MIN(payout_amount) AS min_payout_flagged_approved
FROM claims_full_report2
WHERE fraud_flag = 'Yes'
  AND status = 'Approved'
GROUP BY policy_type, claim_type
order by 3 desc;

SELECT *
FROM (
    SELECT DISTINCT
        policy_type,
        claim_type,
        customer_id,
        payout_amount,
        CASE 
            WHEN payout_amount = MAX(payout_amount) OVER (PARTITION BY policy_type, claim_type) THEN 'Max'
            WHEN payout_amount = MIN(payout_amount) OVER (PARTITION BY policy_type, claim_type) THEN 'Min'
        END AS payout_rank
    FROM claims_full_report2
    WHERE fraud_flag = 'Yes'
      AND status = 'Approved'
) AS ranked
WHERE payout_rank IS NOT NULL
ORDER BY policy_type, claim_type, payout_amount DESC;

-- remove columns not needed
alter table claims_comp_report2
drop column row_num;
 
