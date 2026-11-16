-- ============================================================
-- Bank Loan Analysis — key SQL queries (SQLite)
-- Dataset: 10,000 loan applications, 2023–2025
-- ============================================================

-- 1. Portfolio KPI snapshot
SELECT COUNT(*) applications,
       SUM(loan_amount) total_funded,
       ROUND(AVG(interest_rate),2) avg_rate,
       ROUND(AVG(dti_ratio),1) avg_dti,
       SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END) bad_loans,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans;

-- 2. Default rate by credit grade (the risk ladder)
SELECT grade, COUNT(*) loans, SUM(loan_amount) amount,
       ROUND(AVG(interest_rate),2) avg_rate,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans GROUP BY grade ORDER BY grade;

-- 3. Default rate by purpose
SELECT purpose, COUNT(*) loans, SUM(loan_amount) amount,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans GROUP BY purpose ORDER BY amount DESC;

-- 4. DTI bands vs default rate (policy rule: cap by DTI)
SELECT CASE WHEN dti_ratio < 10 THEN '0-10'
            WHEN dti_ratio < 20 THEN '10-20'
            WHEN dti_ratio < 30 THEN '20-30'
            ELSE '30+' END AS dti_band,
       COUNT(*) loans,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans GROUP BY dti_band ORDER BY dti_band;

-- 5. Income band risk profile
SELECT emp_income_band AS income_band, COUNT(*) loans,
       ROUND(AVG(dti_ratio),1) avg_dti,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans GROUP BY emp_income_band ORDER BY avg_dti;

-- 6. Home ownership as a risk signal
SELECT home_ownership, COUNT(*) loans,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans GROUP BY home_ownership;

-- 7. Term effect (36 vs 60 months)
SELECT term_months, COUNT(*) loans, ROUND(AVG(interest_rate),2) avg_rate,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans GROUP BY term_months;

-- 8. Monthly issuance trend with bad-loan volume
SELECT substr(issue_date,1,7) AS ym, COUNT(*) loans, SUM(loan_amount) amount,
       SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END) bad_loans
FROM loans GROUP BY ym ORDER BY ym;

-- 9. Recovery on bad loans (collections view)
SELECT COUNT(*) bad_loans,
       SUM(loan_amount) exposure,
       SUM(total_paid) recovered,
       ROUND(100.0*SUM(total_paid)/SUM(loan_amount),1) recovery_pct
FROM loans WHERE status IN ('Charged Off','Default');

-- 10. High-risk cohort: grade D/E with DTI>25 — the book a risk officer would cap first
SELECT COUNT(*) loans, SUM(loan_amount) exposure,
       ROUND(100.0*SUM(CASE WHEN status IN ('Charged Off','Default') THEN 1 ELSE 0 END)/COUNT(*),2) default_rate
FROM loans WHERE grade IN ('D','E') AND dti_ratio > 25;
