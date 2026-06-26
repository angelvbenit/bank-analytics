CREATE DATABASE bank_db;
USE bank_db;

DROP TABLE IF EXISTS debitcredit;

CREATE TABLE debitcredit (
    customer_id        TEXT,
    customer_name      TEXT,
    account_number     TEXT,
    transaction_date   TEXT,
    transaction_type   TEXT,
    amount             TEXT,
    balance            TEXT,
    description        TEXT,
    branch             TEXT,
    transaction_method TEXT,
    currency           TEXT,
    bank_name          TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/debitcredit.csv'
INTO TABLE debitcredit
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM debitcredit;

USE bank_db;

-- KPI 1: TOTAL CREDIT
DROP TABLE IF EXISTS kpi1_total_credit;
CREATE TABLE kpi1_total_credit (total_credit DECIMAL(18,4));
INSERT INTO kpi1_total_credit
SELECT SUM(amount) FROM debitcredit WHERE transaction_type = 'Credit';
SELECT * FROM kpi1_total_credit;

-- KPI 2: TOTAL DEBIT
DROP TABLE IF EXISTS kpi2_total_debit;
CREATE TABLE kpi2_total_debit (total_debit DECIMAL(18,4));
INSERT INTO kpi2_total_debit
SELECT SUM(amount) FROM debitcredit WHERE transaction_type = 'Debit';
SELECT * FROM kpi2_total_debit;


-- KPI 3: CREDIT TO DEBIT RATIO
DROP TABLE IF EXISTS kpi3_credit_debit_ratio;
CREATE TABLE kpi3_credit_debit_ratio (credit_to_debit_ratio DECIMAL(10,4));
INSERT INTO kpi3_credit_debit_ratio
SELECT ROUND(
    SUM(CASE WHEN transaction_type = 'Credit' THEN amount ELSE 0 END) /
    NULLIF(SUM(CASE WHEN transaction_type = 'Debit' THEN amount ELSE 0 END), 0),
4) FROM debitcredit;
SELECT * FROM kpi3_credit_debit_ratio;

-- KPI 4: NET TRANSACTION AMOUNT
DROP TABLE IF EXISTS kpi4_net_transaction_amount;
CREATE TABLE kpi4_net_transaction_amount (net_transaction_amount DECIMAL(18,4));
INSERT INTO kpi4_net_transaction_amount
SELECT SUM(CASE WHEN transaction_type = 'Credit' THEN amount
               WHEN transaction_type = 'Debit'  THEN -amount
               ELSE 0 END) FROM debitcredit;
SELECT * FROM kpi4_net_transaction_amount;

-- KPI 5: ACCOUNT ACTIVITY RATIO
DROP TABLE IF EXISTS kpi5_account_activity_ratio;
CREATE TABLE kpi5_account_activity_ratio (overall_account_activity_ratio DECIMAL(18,6));
INSERT INTO kpi5_account_activity_ratio
SELECT COUNT(*) / NULLIF(AVG(balance), 0) FROM debitcredit;
SELECT * FROM kpi5_account_activity_ratio;

-- KPI 6a: TRANSACTIONS PER DAY
DROP TABLE IF EXISTS kpi6a_txn_per_day;
CREATE TABLE kpi6a_txn_per_day (txn_day DATE, total_transactions INT);
INSERT INTO kpi6a_txn_per_day
SELECT DATE(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY)), COUNT(*)
FROM debitcredit GROUP BY 1 ORDER BY 1;
SELECT * FROM kpi6a_txn_per_day;

-- KPI 6b: TRANSACTIONS PER WEEK
DROP TABLE IF EXISTS kpi6b_txn_per_week;
CREATE TABLE kpi6b_txn_per_week (txn_week VARCHAR(20), total_transactions INT);
INSERT INTO kpi6b_txn_per_week
SELECT DATE_FORMAT(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY), '%Y - Week %u'), COUNT(*)
FROM debitcredit GROUP BY 1 ORDER BY 1;
SELECT * FROM kpi6b_txn_per_week;

-- KPI 6c: TRANSACTIONS PER MONTH
DROP TABLE IF EXISTS kpi6c_txn_per_month;
CREATE TABLE kpi6c_txn_per_month (txn_month VARCHAR(10), total_transactions INT);
INSERT INTO kpi6c_txn_per_month
SELECT DATE_FORMAT(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY), '%Y-%m'), COUNT(*)
FROM debitcredit GROUP BY 1 ORDER BY 1;
SELECT * FROM kpi6c_txn_per_month;

-- KPI 7: TOTAL TRANSACTION AMOUNT BY BRANCH
DROP TABLE IF EXISTS kpi7_amount_by_branch;
CREATE TABLE kpi7_amount_by_branch (branch VARCHAR(100), total_amount DECIMAL(18,4));
INSERT INTO kpi7_amount_by_branch
SELECT branch, SUM(amount) FROM debitcredit GROUP BY branch ORDER BY 2 DESC;
SELECT * FROM kpi7_amount_by_branch;

-- KPI 8: TRANSACTION VOLUME BY BANK
DROP TABLE IF EXISTS kpi8_volume_by_bank;
CREATE TABLE kpi8_volume_by_bank (bank_name VARCHAR(100), total_volume DECIMAL(18,4));
INSERT INTO kpi8_volume_by_bank
SELECT bank_name, SUM(amount) FROM debitcredit GROUP BY bank_name ORDER BY 2 DESC;
SELECT * FROM kpi8_volume_by_bank;

-- KPI 9: TRANSACTION METHOD DISTRIBUTION
DROP TABLE IF EXISTS kpi9_method_distribution;
CREATE TABLE kpi9_method_distribution (transaction_method VARCHAR(100), transaction_count INT, percentage_distribution DECIMAL(6,2));
INSERT INTO kpi9_method_distribution
SELECT transaction_method, COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM debitcredit), 2)
FROM debitcredit GROUP BY transaction_method ORDER BY 2 DESC;
SELECT * FROM kpi9_method_distribution;

-- KPI 10: BRANCH TRANSACTION GROWTH
DROP TABLE IF EXISTS kpi10_branch_mom_growth;
CREATE TABLE kpi10_branch_mom_growth (branch VARCHAR(100), txn_month VARCHAR(10), monthly_volume DECIMAL(18,4), prev_month_volume DECIMAL(18,4), mom_growth_pct DECIMAL(10,2));
INSERT INTO kpi10_branch_mom_growth
WITH MonthlyBranchVolume AS (
    SELECT branch,
        DATE_FORMAT(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY), '%Y-%m') AS Txn_Month,
        SUM(amount) AS Monthly_Volume
    FROM debitcredit GROUP BY branch, Txn_Month
)
SELECT branch, Txn_Month, Monthly_Volume,
    LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month),
    ROUND(
        ((Monthly_Volume - LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month)) /
        NULLIF(LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month), 0)) * 100, 2
    )
FROM MonthlyBranchVolume;
SELECT * FROM kpi10_branch_mom_growth;

-- KPI 11: HIGH RISK TRANSACTION FLAG
DROP TABLE IF EXISTS kpi11_high_risk_transactions;
CREATE TABLE kpi11_high_risk_transactions (customer_id TEXT, account_number TEXT, readable_date DATE, amount TEXT, risk_flag VARCHAR(20), threshold_used TEXT);
INSERT INTO kpi11_high_risk_transactions
WITH DynamicThreshold AS (
    SELECT amount AS high_risk_cutoff
    FROM (
        SELECT amount, PERCENT_RANK() OVER (ORDER BY amount) AS pct_rank
        FROM debitcredit
    ) RankedData
    WHERE pct_rank >= 0.95
    ORDER BY amount ASC
    LIMIT 1
)
SELECT d.customer_id, d.account_number,
    DATE(DATE_ADD('1899-12-30', INTERVAL d.transaction_date DAY)),
    d.amount, 'High Risk', t.high_risk_cutoff
FROM debitcredit d CROSS JOIN DynamicThreshold t
WHERE d.amount > t.high_risk_cutoff;
SELECT * FROM kpi11_high_risk_transactions;

-- KPI 12: SUSPICIOUS TRANSACTION COUNT
DROP TABLE IF EXISTS kpi12_suspicious_txn_count;
CREATE TABLE kpi12_suspicious_txn_count (total_suspicious_transactions INT);
INSERT INTO kpi12_suspicious_txn_count
WITH DynamicThreshold AS (
    SELECT amount AS high_risk_cutoff
    FROM (
        SELECT amount, PERCENT_RANK() OVER (ORDER BY amount) AS pct_rank
        FROM debitcredit
    ) RankedData
    WHERE pct_rank >= 0.95
    ORDER BY amount ASC
    LIMIT 1
)
SELECT COUNT(*) FROM debitcredit d
CROSS JOIN DynamicThreshold t
WHERE d.amount > t.high_risk_cutoff;

SELECT * FROM kpi12_suspicious_txn_count;

-- KPI 13: TOTAL TRANSACTIONS
DROP TABLE IF EXISTS kpi13_total_transactions;
CREATE TABLE kpi13_total_transactions (total_transactions INT);
INSERT INTO kpi13_total_transactions
SELECT COUNT(*) FROM debitcredit;
 select * from kpi13_total_transactions;