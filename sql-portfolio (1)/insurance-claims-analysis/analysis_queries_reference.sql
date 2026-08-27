-- ============================================================
-- Insurance Claims Analysis — Reference Query Log
-- NOTE: This is a reconstructed reference based on project notes.
-- Replace/merge with your own saved .sql file from MySQL Workbench,
-- which contains your original, exact queries.
-- ============================================================

-- 1. DATA PREPARATION -----------------------------------------

-- Remove title prefixes (Dr., Mrs., Mr., Ms.) while keeping suffixes (MD, DDS, Jr.)
UPDATE insurance_claims.customers
SET customer_name = TRIM(
    REPLACE(REPLACE(REPLACE(REPLACE(customer_name,
        'Dr. ', ''), 'Mrs. ', ''), 'Mr. ', ''), 'Ms. ', '')
)
WHERE customer_name LIKE 'Dr. %'
   OR customer_name LIKE 'Mrs. %'
   OR customer_name LIKE 'Mr. %'
   OR customer_name LIKE 'Ms. %';

-- Standardize inconsistent status casing
UPDATE claims_full_report2
SET status = 'Under Review'
WHERE status LIKE 'under%';

-- Convert claim_date from text to DATE
ALTER TABLE claims_full_report2
MODIFY COLUMN claim_date DATE;

-- Drop temporary helper column
ALTER TABLE claims_comp_report2
DROP COLUMN row_num;


-- 2. BUILDING THE JOINED REPORT --------------------------------

-- Full picture: every customer, even without a policy or claim
CREATE TABLE claims_full_report_all_customers AS
SELECT
    c.customer_id, c.customer_name, c.gender, c.age, c.region, c.signup_date,
    p.policy_id, p.policy_type, p.premium_amount,
    p.start_date AS policy_start_date, p.end_date AS policy_end_date,
    cl.claim_id, cl.claim_type, cl.claim_date,
    cl.amount_claimed, cl.payout_amount, cl.status, cl.fraud_flag
FROM customers c
LEFT JOIN policies p ON c.customer_id = p.customer_id
LEFT JOIN claims cl ON p.policy_id = cl.policy_id;

-- Active picture: only customers with a policy AND a filed claim
CREATE TABLE claims_full_report_active_only AS
SELECT
    c.customer_id, c.customer_name, c.gender, c.age, c.region, c.signup_date,
    p.policy_id, p.policy_type, p.premium_amount,
    p.start_date AS policy_start_date, p.end_date AS policy_end_date,
    cl.claim_id, cl.claim_type, cl.claim_date,
    cl.amount_claimed, cl.payout_amount, cl.status, cl.fraud_flag
FROM customers c
JOIN policies p ON c.customer_id = p.customer_id
JOIN claims cl ON p.policy_id = cl.policy_id;


-- 3. VOLUME ANALYSIS --------------------------------------------

-- Policies and claims per customer
SELECT
    customer_id, customer_name,
    COUNT(DISTINCT policy_id) AS num_policies,
    COUNT(DISTINCT claim_id) AS num_claims
FROM claims_full_report2
GROUP BY customer_id, customer_name
ORDER BY num_claims DESC;

-- Claims-per-policy ratio by gender
SELECT
    gender,
    COUNT(DISTINCT policy_id) AS num_policies,
    COUNT(DISTINCT claim_id) AS num_claims,
    ROUND(COUNT(DISTINCT claim_id) / COUNT(DISTINCT policy_id), 2) AS claims_per_policy
FROM claims_full_report2
GROUP BY gender
ORDER BY claims_per_policy DESC;

-- Claim status breakdown with percentage share
SELECT
    status,
    COUNT(*) AS total_claims,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM claims_full_report2), 1) AS pct_of_total
FROM claims_full_report2
GROUP BY status
ORDER BY total_claims DESC;


-- 4. FINANCIAL EXPOSURE -------------------------------------------

-- Total claimed vs. paid out (full book)
SELECT
    SUM(amount_claimed) AS total_claimed,
    SUM(payout_amount) AS total_paid_out,
    SUM(amount_claimed) - SUM(payout_amount) AS total_shortfall
FROM claims_full_report2;

-- Open exposure: claims still Pending or Under Review
SELECT
    status,
    COUNT(*) AS num_claims,
    SUM(amount_claimed) AS total_claimed_pending_decision
FROM claims_full_report2
WHERE status IN ('Pending', 'Under Review')
GROUP BY status;

-- Payout gap broken down by status
SELECT
    status,
    COUNT(*) AS num_claims,
    SUM(amount_claimed) AS total_claimed,
    SUM(payout_amount) AS total_paid,
    SUM(amount_claimed) - SUM(payout_amount) AS gap
FROM claims_full_report2
GROUP BY status
ORDER BY gap DESC;


-- 5. FRAUD FLAG REVIEW ----------------------------------------------

-- Overall % flagged, and flagged-but-approved count
SELECT
    COUNT(DISTINCT claim_id) AS total_claims,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' THEN claim_id END) AS total_flagged,
    ROUND(
        COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' THEN claim_id END) * 100.0
        / COUNT(DISTINCT claim_id), 2
    ) AS pct_flagged,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' AND status = 'Approved'
        THEN claim_id END) AS flagged_but_approved
FROM claims_full_report2;

-- Flagged / flagged-and-approved breakdown by policy type
SELECT
    policy_type,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' THEN claim_id END) AS flagged_claims,
    COUNT(DISTINCT CASE WHEN fraud_flag = 'Yes' AND status = 'Approved'
        THEN claim_id END) AS flagged_and_approved
FROM claims_full_report2
GROUP BY policy_type
ORDER BY flagged_claims DESC;

-- Max/min flagged-and-approved payout by policy type and claim type
SELECT
    policy_type,
    claim_type,
    customer_id,
    MAX(payout_amount) AS max_payout_flagged_approved,
    MIN(payout_amount) AS min_payout_flagged_approved
FROM claims_full_report2
WHERE fraud_flag = 'Yes'
  AND status = 'Approved'
GROUP BY policy_type, claim_type, customer_id;

-- Window-function version: rank max/min within category, tied to customer
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
