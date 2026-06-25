# 🏦 Bank Transaction Analytics: SQL Project

A end-to-end SQL analytics project that ingests bank transaction data, stores it in a relational database, and computes 12 business KPIs covering transaction volumes, branch performance, risk detection, and growth trends.

---

## Database Setup

**Database:** `bank_db`  
**Table:** `debitcredit`  
**Engine:** MySQL (uses `LOAD DATA LOCAL INFILE`, `DATE_FORMAT`, `PERCENT_RANK`, window functions)

### Table Schema

| Column               | Type   | Description                                      |
|----------------------|--------|--------------------------------------------------|
| `customer_id`        | TEXT   | UUID uniquely identifying the customer           |
| `customer_name`      | TEXT   | Full name of the account holder                  |
| `account_number`     | TEXT   | 10-digit bank account number                     |
| `transaction_date`   | TEXT   | Date stored as Excel serial number (days since 1899-12-30) |
| `transaction_type`   | TEXT   | `Credit` or `Debit`                              |
| `amount`             | TEXT   | Transaction amount in INR                        |
| `balance`            | TEXT   | Account balance after the transaction            |
| `description`        | TEXT   | Nature of the transaction (e.g., Salary Deposit, Online Shopping) |
| `branch`             | TEXT   | Branch where transaction occurred                |
| `transaction_method` | TEXT   | Payment method: `Credit Card`, `Debit Card`, `Bank Transfer` |
| `currency`           | TEXT   | Currency code (all transactions in `INR`)        |
| `bank_name`          | TEXT   | Bank name (e.g., HDFC Bank, ICICI Bank, Axis Bank) |

> **Note on Dates:** `transaction_date` is stored as an Excel serial integer (e.g., `45404`). All date-based queries convert this using `DATE_ADD('1899-12-30', INTERVAL transaction_date DAY)`.

---

## Dataset Overview

| Property              | Detail                                                              |
|-----------------------|---------------------------------------------------------------------|
| Total Records         | ~1,0000 transactions                                                 |
| Currency              | INR (Indian Rupee)                                                  |
| Banks Covered         | Axis Bank, HDFC Bank, ICICI Bank, Kotak Mahindra Bank, State Bank of India, Punjab National Bank |
| Branches              | Main Branch, City Center Branch, North Branch, East Branch, Suburban Branch, Downtown Branch |
| Transaction Types     | Credit, Debit                                                       |
| Payment Methods       | Credit Card, Debit Card, Bank Transfer                              |
| Transaction Categories | Salary Deposit, Bonus Payment, Client Payment, Freelance Payment, Online Shopping, Grocery Shopping, Utility Bill Payment, Refund from Retailer, Refund for Overcharge, Dinner at Restaurant, Dinner at Restaurant |

---

## Setup Instructions

### 1. Prerequisites
- MySQL Server 8.0+ 
- MySQL client or Workbench

### 2. Enable Local File Loading

```sql
SET GLOBAL local_infile = 1;
```

> Run this as a MySQL superuser before executing the load script.

### 3. Create Database and Table

```sql
CREATE DATABASE bank_db;
USE bank_db;

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
```

### 4. Load Data

Update the file path in the script to match your local machine before running:

```sql
LOAD DATA LOCAL INFILE 'D:/your_path/debitcredit.csv'
INTO TABLE debitcredit
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

### 5. Verify Load

```sql
SELECT COUNT(*) FROM debitcredit;
-- Expected: ~10000 rows
```

---

## KPI Reference

### KPI 1: Total Credit Amount

**Business Question:** How much money has been credited across all accounts in total?

```sql
SELECT SUM(amount) AS total_credit
FROM debitcredit
WHERE transaction_type = 'Credit';
```

**Insight:** Gives the gross inflow of funds. Useful for understanding the overall credit health of the bank's customers.

---

### KPI 2: Total Debit Amount

**Business Question:** How much money has been debited across all accounts in total?

```sql
SELECT SUM(amount) AS total_debit
FROM debitcredit
WHERE transaction_type = 'Debit';
```

**Insight:** Measures gross outflow. Comparing this with KPI 1 shows whether the customer base is net-saving or net-spending.

---

### KPI 3: Credit to Debit Ratio

**Business Question:** For every rupee debited, how many rupees are being credited?

```sql
SELECT ROUND(
    SUM(CASE WHEN transaction_type = 'Credit' THEN amount ELSE 0 END) /
    NULLIF(SUM(CASE WHEN transaction_type = 'Debit' THEN amount ELSE 0 END), 0),
4) AS credit_to_debit_ratio
FROM debitcredit;
```

**Insight:** A ratio > 1 means more money is coming in than going out. `NULLIF` prevents a division-by-zero error if there are no debit transactions.

---

### KPI 4: Net Transaction Amount

**Business Question:** What is the net fund flow (credits minus debits) across all transactions?

```sql
SELECT SUM(CASE WHEN transaction_type = 'Credit' THEN amount
               WHEN transaction_type = 'Debit'  THEN -amount
               ELSE 0 END) AS net_transaction_amount
FROM debitcredit;
```

**Insight:** A positive result indicates overall fund accumulation; a negative result indicates a net outflow. This is a single-number health indicator for the portfolio.

---

### KPI 5: Account Activity Ratio

**Business Question:** How active are accounts relative to their average balance?

```sql
SELECT 
    COUNT(*) / NULLIF(AVG(balance), 0) AS Overall_Account_Activity_Ratio
FROM debitcredit;
```

**Insight:** Divides total transaction count by average account balance. A higher ratio suggests customers are transacting frequently relative to their holdings — indicating high engagement or potential liquidity pressure.

---

### KPI 6: Transaction Frequency (Daily / Weekly / Monthly)

**Business Question:** When are customers most active — which days, weeks, and months see the highest transaction counts?

```sql
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
```

**Insight:** Identifies peak and off-peak periods. Useful for staffing, server capacity planning, and targeted marketing campaigns (e.g., promotions during low-activity months).

> **Date conversion explained:** `DATE_ADD('1899-12-30', INTERVAL transaction_date DAY)` converts Excel's serial date integer back to a human-readable SQL date.

---

### KPI 7: Total Transaction Amount by Branch

**Business Question:** Which branches are processing the most transaction value?

```sql
SELECT branch, SUM(amount) AS Total_Amount
FROM debitcredit
GROUP BY branch
ORDER BY Total_Amount DESC;
```

**Insight:** Ranks branches by rupee volume. Highlights high-performing branches and those that may need attention or resources.

---

### KPI 8: Transaction Volume by Bank

**Business Question:** Which bank is handling the highest transaction value across the network?

```sql
SELECT bank_name, SUM(amount) AS Total_Volume
FROM debitcredit
GROUP BY bank_name
ORDER BY Total_Volume DESC;
```

**Insight:** Useful for inter-bank comparisons. Can surface which banking partners have the most customer activity.

---

### KPI 9: Transaction Method Distribution

**Business Question:** What percentage of transactions are done via Credit Card, Debit Card, and Bank Transfer?

```sql
SELECT 
    transaction_method, 
    COUNT(*) AS Transaction_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM debitcredit), 2) AS Percentage_Distribution
FROM debitcredit
GROUP BY transaction_method
ORDER BY Transaction_Count DESC;
```

**Insight:** Shows customer payment behaviour. If Bank Transfer dominates, it suggests corporate/bulk users. If Debit Card is most common, it indicates retail consumer behaviour. Informs product and infrastructure decisions.

---

### KPI 10: Branch Transaction Growth (Month-over-Month)

**Business Question:** Is each branch growing, declining, or staying flat in transaction volume month over month?

```sql
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
    ROUND(
        ((Monthly_Volume - LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month)) / 
        NULLIF(LAG(Monthly_Volume) OVER(PARTITION BY branch ORDER BY Txn_Month), 0)) * 100, 2
    ) AS MoM_Growth_Percentage
FROM MonthlyBranchVolume;
```

**Insight:** Uses the `LAG()` window function to compare each month against the prior month, partitioned by branch. A negative `MoM_Growth_Percentage` flags a branch that needs investigation. Useful for strategic resource reallocation.

---

### KPI 11: High-Risk Transaction Flagging

**Business Question:** Which individual transactions are unusually large and potentially high-risk?

```sql
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
```

**Insight:** Dynamically identifies the top 5% of transactions by amount using `PERCENT_RANK()`. Unlike a hardcoded threshold, this adapts automatically as the data grows. Each flagged row is tagged `'High Risk'` for easy downstream filtering or reporting.

---

### KPI 12: Suspicious Transaction Count

**Business Question:** How many transactions in total exceed the high-risk threshold?

```sql
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
SELECT 
    COUNT(*) AS Total_Suspicious_Transactions
FROM debitcredit d
CROSS JOIN DynamicThreshold t
WHERE d.amount > t.high_risk_cutoff;
```

**Insight:** Provides a single headline count of high-risk transactions. Use this as a dashboard KPI metric alongside KPI 11 for drill-down. By definition, this should be approximately 5% of the total transaction count.

---

## Key SQL Concepts Used

| Concept                     | Where Used                          |
|-----------------------------|-------------------------------------|
| `SUM` with `CASE WHEN`      | KPIs 3, 4 — conditional aggregation |
| `NULLIF`                    | KPIs 3, 5, 10 — division-by-zero guard |
| `DATE_ADD` with serial date | KPIs 6, 10, 11 — Excel date conversion |
| `DATE_FORMAT`               | KPIs 6, 10 — weekly and monthly grouping |
| `PERCENT_RANK()`            | KPIs 11, 12 — dynamic threshold via percentile |
| `LAG()` window function     | KPI 10 — month-over-month comparison |
| `CROSS JOIN` with CTE       | KPIs 11, 12 — broadcasting threshold to all rows |
| Common Table Expressions    | KPIs 10, 11, 12 — readability and reuse |

---

## Notes

**Excel Serial Date Conversion**
All dates in the dataset are stored as Excel serial integers. The formula `DATE_ADD('1899-12-30', INTERVAL transaction_date DAY)` is the correct MySQL equivalent of Excel's date origin.

**Dynamic vs. Static Thresholds (KPIs 11 & 12)**
The high-risk cutoff uses `PERCENT_RANK()` rather than a hardcoded number. This means the threshold automatically adjusts as new data is added making it production-safe without manual recalibration.

**`NULLIF` Pattern**
Wherever division occurs (KPIs 3, 5, 10), `NULLIF(denominator, 0)` is used to return `NULL` instead of throwing a division-by-zero error. This is especially important in production where some branches or months may have no prior-month data.


## Summary Table of KPIs

| # | KPI Name                        | Output Type      | Primary Use Case              |
|---|---------------------------------|------------------|-------------------------------|
| 1 | Total Credit Amount             | Scalar           | Financial overview            |
| 2 | Total Debit Amount              | Scalar           | Financial overview            |
| 3 | Credit to Debit Ratio           | Scalar           | Fund flow health              |
| 4 | Net Transaction Amount          | Scalar           | Net fund position             |
| 5 | Account Activity Ratio          | Scalar           | Customer engagement           |
| 6 | Transactions Per Day/Week/Month | Time series      | Trend & seasonality analysis  |
| 7 | Total Amount by Branch          | Ranked table     | Branch performance            |
| 8 | Volume by Bank                  | Ranked table     | Partner bank comparison       |
| 9 | Payment Method Distribution     | Distribution (%) | Customer behaviour insights   |
| 10| Branch MoM Growth               | Time series      | Growth tracking & alerts      |
| 11| High-Risk Transaction Flags     | Flagged records  | Fraud / AML monitoring        |
| 12| Suspicious Transaction Count    | Scalar           | Risk dashboard headline KPI   |

---
