# Insurance Claims Analysis (MySQL)

## Overview
Relational analysis across a customers/policies/claims dataset, answering business
questions relevant to underwriting, claims operations, and fraud review.

## Dataset Structure
- `customers` — customer_id, name, gender, age, region, signup_date
- `policies` — policy_id, customer_id, policy_type, premium_amount, start_date, end_date
- `claims` — claim_id, policy_id, claim_type, claim_date, amount_claimed,
  payout_amount, status, fraud_flag

Relationship: one customer → many policies → many claims.

## Key Analysis
1. **Data preparation** — standardized name formatting (removed title prefixes, kept
   professional suffixes), fixed inconsistent status casing, converted `claim_date`
   from text to `DATE`, dropped temporary working columns
2. **Joins** — built a full relational report using INNER and LEFT JOIN depending on
   the business question (e.g., LEFT JOIN to include customers with no policy history)
3. **Volume analysis** — policies/claims per customer, claims-per-policy ratio by
   gender, claim status breakdown with percentage share
4. **Financial exposure** — total claimed vs. paid out, open exposure on unresolved
   claims, payout gap broken down by status
5. **Fraud review** — % of claims flagged, flagged-but-approved claims (process-risk
   indicator), breakdown by policy type, and highest/lowest flagged-approved payouts
   by category using window functions

## Key Finding
Travel policies carried the highest **volume** of flagged and flagged-approved claims,
while Life policies (Death Benefit claims) carried the highest single **payout amount**
among flagged-approved claims — a volume vs. severity distinction relevant to
prioritizing fraud review resources.

## Files
- [`analysis_queries.sql`](./analysis_queries.sql) — full query log
- [`project_summary.docx`](./project_summary.docx) — written summary of findings
