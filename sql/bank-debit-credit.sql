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

SET GLOBAL local_infile = 1;

USE bank_db;

LOAD DATA LOCAL INFILE 'D:/excelr/PROJECT 2/by me/debitcredit.csv'
INTO TABLE debitcredit
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM debitcredit;

### KPI 1: TOTAL CREDIT ###
SELECT SUM(amount) AS total_credit
FROM debitcredit
WHERE transaction_type = 'Credit';

### KPI 2: TOTAL DEBIT ###
SELECT SUM(amount) AS total_debit
FROM debitcredit
WHERE transaction_type = 'Debit';

### KPI 3: CREDIT TO DEBIT RATIO ###
SELECT ROUND(
    SUM(CASE WHEN transaction_type = 'Credit' THEN amount ELSE 0 END) /
    NULLIF(SUM(CASE WHEN transaction_type = 'Debit' THEN amount ELSE 0 END), 0),
4) AS credit_to_debit_ratio
FROM debitcredit;

### KPI 4: NET TRANSACTION AMOUNT ###
SELECT SUM(CASE WHEN transaction_type = 'Credit' THEN amount
               WHEN transaction_type = 'Debit'  THEN -amount
               ELSE 0 END) AS net_transaction_amount
FROM debitcredit;

### KPI 5: ACCOUNT ACTIVITY RATIO ###
SELECT 
    COUNT(*) / NULLIF(AVG(balance), 0) AS Overall_Account_Activity_Ratio
FROM debitcredit;


### kpi 6: transactions per day week and month ###
-- Per Day
SELECT 
    DATE(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY)) AS Txn_Day, 
    COUNT(*) AS Total_Transactions
FROM debitcredit
GROUP BY Txn_Day
ORDER BY Txn_Day;

-- Per Week
SELECT 
    DATE_FORMAT(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY), '%Y - Week %u') AS Txn_Week, 
    COUNT(*) AS Total_Transactions
FROM debitcredit
GROUP BY Txn_Week
ORDER BY Txn_Week;

-- Per Month
SELECT 
    DATE_FORMAT(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY), '%Y-%m') AS Txn_Month, 
    COUNT(*) AS Total_Transactions
FROM debitcredit
GROUP BY Txn_Month
ORDER BY Txn_Month;

### KPI 7: Total transactions amount by branch ###
SELECT branch, SUM(amount) AS Total_Amount
FROM debitcredit
GROUP BY branch
ORDER BY Total_Amount DESC;

### KPI 8: Transaction volume by branch ###
SELECT bank_name, SUM(amount) AS Total_Volume
FROM debitcredit
GROUP BY bank_name
ORDER BY Total_Volume DESC;

### KPI 9: Transaction Method Distribution ###
SELECT 
    transaction_method, 
    COUNT(*) AS Transaction_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM debitcredit), 2) AS Percentage_Distribution
FROM debitcredit
GROUP BY transaction_method
ORDER BY Transaction_Count DESC;

### kpi 10: branch transaction growth ###
WITH MonthlyBranchVolume AS (
    SELECT 
        branch,
        DATE_FORMAT(DATE_ADD('1899-12-30', INTERVAL transaction_date DAY), '%Y-%m') AS Txn_Month,
        SUM(amount) AS Monthly_Volume
    FROM debitcredit
    GROUP BY branch, Txn_Month
)
SELECT 
    branch,
    Txn_Month,
    Monthly_Volume,
    LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month) AS Prev_Month_Volume,
    
    -- Calculates the % growth. NULLIF prevents division by zero errors.
    ROUND(
        ((Monthly_Volume - LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month)) / 
        NULLIF(LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month), 0)) * 100, 2
    ) AS MoM_Growth_Percentage
    
FROM MonthlyBranchVolume;

### KPI 11: High risk transaction flag ###
WITH DynamicThreshold AS (
    -- Finds the exact cutoff amount for the top 5%
    SELECT amount AS high_risk_cutoff
    FROM (
        SELECT amount, PERCENT_RANK() OVER (ORDER BY amount) AS pct_rank
        FROM debitcredit
    ) RankedData
    WHERE pct_rank >= 0.95
    ORDER BY amount ASC
    LIMIT 1
)
SELECT 
    d.customer_id, 
    d.account_number, 
    DATE(DATE_ADD('1899-12-30', INTERVAL d.transaction_date DAY)) AS Readable_Date, 
    d.amount,
    'High Risk' AS Risk_Flag,
    t.high_risk_cutoff AS Threshold_Used
FROM debitcredit d
CROSS JOIN DynamicThreshold t
WHERE d.amount > t.high_risk_cutoff;

## KPI 12: Suspicious transaction frequency ###
WITH DynamicThreshold AS (
    -- Finds the exact cutoff amount for the top 5%
    SELECT amount AS high_risk_cutoff
    FROM (
        SELECT amount, PERCENT_RANK() OVER (ORDER BY amount) AS pct_rank
        FROM debitcredit
    ) RankedData
    WHERE pct_rank >= 0.95
    ORDER BY amount ASC
    LIMIT 1
)
SELECT 
    COUNT(*) AS Total_Suspicious_Transactions
FROM debitcredit d
CROSS JOIN DynamicThreshold t
WHERE d.amount > t.high_risk_cutoff;