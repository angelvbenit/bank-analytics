# Bank Analytics: SQL Project

An end-to-end SQL analytics project that ingests microfinance loan data from a star-schema Excel workbook, loads it into a relational MySQL database, and computes 17 business KPIs covering client activity, loan disbursement, repayment health, risk detection, branch performance, and product profitability.

---

## Database Setup

**Database:** `bank_db`  
**Tables:** `dim_client`, `dim_branch`, `dim_product`, `fact_loan`, `fact_repayment`  
**Engine:** MySQL 8.0+ (uses window functions, CTEs, foreign keys, STR_TO_DATE)

### Schema Overview

```
dim_client ──┐
dim_branch ──┼──► fact_loan ──► fact_repayment
dim_product ─┘
```

`fact_loan` is the central fact table. It links to all three dimension tables via foreign keys, and to `fact_repayment` via `Account_ID`.

---

### Table Schema

#### dim_client
| Column | Type | Description |
|---|---|---|
| `Client_id` | INT (PK) | Unique client identifier |
| `Client_Name` | VARCHAR(255) | Full name of the client |
| `Credit_Score` | INT | Credit score (range: 300–847) |

> **Note:** The source sheet also contains Gender, Age, Caste, Religion, Home Ownership, Income Range, and Employment Type, only the columns needed for KPIs are loaded.

#### dim_branch
| Column | Type | Description |
|---|---|---|
| `Branch_ID` | VARCHAR(100) (PK) | Unique branch identifier (e.g., `Mathura-910182`) |
| `Branch_Name` | VARCHAR(100) | Name of the branch city |
| `Branch_Performance_Category` | VARCHAR(50) | Performance tier: `High`, `Medium`, or `Low` |

#### dim_product
| Column | Type | Description |
|---|---|---|
| `Product_Id` | VARCHAR(50) (PK) | Unique product identifier |
| `Purpose_Category` | VARCHAR(100) | Loan purpose: Services, Agriculture, Education, Home Loan, Trade, Property, Car Loan, Factory |

#### fact_loan
| Column | Type | Description |
|---|---|---|
| `Account_ID` | VARCHAR(50) (PK) | Unique loan account identifier |
| `Client_id` | INT (FK) | References `dim_client` |
| `Branch_ID` | VARCHAR(100) (FK) | References `dim_branch` |
| `Product_Id` | VARCHAR(50) (FK) | References `dim_product` |
| `Loan_Amount` | DECIMAL(15,2) | Sanctioned loan amount in INR (range: ₹2,024–₹49,995) |
| `Funded_Amount` | DECIMAL(15,2) | Amount actually disbursed (range: ₹2,013–₹49,906) |
| `Disbursement_Date` | DATE | Date the loan was disbursed (2015–2023) |
| `Loan_Status` | VARCHAR(50) | Current status: `Active`, `Fully Paid`, `Paid Off`, `Default` |

#### fact_repayment
| Column | Type | Description |
|---|---|---|
| `Account_ID` | VARCHAR(50) (PK, FK) | References `fact_loan` |
| `Total_Pymnt` | DECIMAL(15,2) | Total amount repaid by the borrower |
| `Total_Rec_Prncp` | DECIMAL(15,2) | Principal amount recovered |
| `Total_Rrec_int` | DECIMAL(15,2) | Interest income collected |
| `Is_Delinquent_Loan` | VARCHAR(5) | Whether loan is delinquent: `Y` or `N` |
| `Is_Default_Loan` | VARCHAR(5) | Whether loan has defaulted: `Y` or `N` |
| `Repayment_Behavior` | VARCHAR(50) | Payment pattern: `On-Time`, `Late`, `Very Late` |

---

## Dataset Overview

| Property | Detail |
|---|---|
| Total Loan Records | 2,000 |
| Total Clients | 1,000 |
| Total Branches | 180 |
| Total Products | 11 |
| Date Range | 2015–2023 |
| Currency | INR (Indian Rupee) |
| Loan Amount Range | ₹2,024 – ₹49,995 |
| Loan Statuses | Active, Fully Paid, Paid Off, Default |
| Repayment Types | Monthly EMI, Quarterly EMI |
| Branch Performance Tiers | High (58), Medium (57), Low (65) |
| Regions Covered | Ludhiana, Bulandshahr, Raipur, Jaipur, Karnal, Varanasi, Patna, Howrah, Bhopal, Bhubaneswar, Guwahati |
| Default Rate | 5% (100 of 2,000 loans) |
| Delinquency Rate | 10.35% (207 of 2,000 loans) |
| On-Time Repayment Rate | 71.05% (1,421 of 2,000) |

---

## Setup Instructions

### 1. Prerequisites
- MySQL Server 8.0+
- MySQL Workbench or any MySQL client
- Source dataset exported as 5 separate CSV files (one per sheet)

### 2. Export CSVs from Excel

Open `dataset1.xlsx`, right-click each sheet tab → **Save As CSV** with these exact filenames:
- `dim_client.csv`
- `dim_branch.csv`
- `dim_product.csv`
- `fact_loan.csv`
- `fact_repayment.csv`

### 3. Copy CSVs to MySQL Upload Folder

```
C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\
```

> ProgramData is a hidden folder. Enable **View → Hidden Items** in File Explorer to find it.  
> To confirm your path: `SHOW VARIABLES LIKE 'secure_file_priv';`

### 4. Create Database and Tables

```sql
CREATE DATABASE IF NOT EXISTS bank_db;
USE bank_db;

CREATE TABLE dim_client (
    Client_id    INT PRIMARY KEY,
    Client_Name  VARCHAR(255),
    Credit_Score INT
);

CREATE TABLE dim_branch (
    Branch_ID                   VARCHAR(100) PRIMARY KEY,
    Branch_Name                 VARCHAR(100),
    Branch_Performance_Category VARCHAR(50)
);

CREATE TABLE dim_product (
    Product_Id       VARCHAR(50) PRIMARY KEY,
    Purpose_Category VARCHAR(100)
);

CREATE TABLE fact_loan (
    Account_ID        VARCHAR(50) PRIMARY KEY,
    Client_id         INT,
    Branch_ID         VARCHAR(100),
    Product_Id        VARCHAR(50),
    Loan_Amount       DECIMAL(15,2),
    Funded_Amount     DECIMAL(15,2),
    Disbursement_Date DATE,
    Loan_Status       VARCHAR(50),
    FOREIGN KEY (Client_id)  REFERENCES dim_client(Client_id),
    FOREIGN KEY (Branch_ID)  REFERENCES dim_branch(Branch_ID),
    FOREIGN KEY (Product_Id) REFERENCES dim_product(Product_Id)
);

CREATE TABLE fact_repayment (
    Account_ID         VARCHAR(50) PRIMARY KEY,
    Total_Pymnt        DECIMAL(15,2),
    Total_Rec_Prncp    DECIMAL(15,2),
    Total_Rrec_int     DECIMAL(15,2),
    Is_Delinquent_Loan VARCHAR(5),
    Is_Default_Loan    VARCHAR(5),
    Repayment_Behavior VARCHAR(50),
    FOREIGN KEY (Account_ID) REFERENCES fact_loan(Account_ID)
);
```

### 5. Load Data

```sql
-- Load Clients (selects only needed columns using @dummy for skipped ones)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_client.csv'
INTO TABLE dim_client FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(Client_id, Client_Name, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, Credit_Score);

-- Load Branches
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_branch.csv'
INTO TABLE dim_branch FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(Branch_Name, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, Branch_Performance_Category, Branch_ID);

-- Load Products
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_product.csv'
INTO TABLE dim_product FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(Product_Id, @dummy, Purpose_Category, @dummy, @dummy, @dummy, @dummy);

-- Load Fact Loan (converts raw datetime string to DATE)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_loan.csv'
INTO TABLE fact_loan FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(Account_ID, Client_id, @dummy, Product_Id, Loan_Amount, Funded_Amount, @dummy, @raw_date, Loan_Status, @dummy, @dummy, Branch_ID)
SET Disbursement_Date = STR_TO_DATE(SUBSTRING(@raw_date, 1, 10), '%Y-%m-%d');

-- Load Fact Repayment
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_repayment.csv'
INTO TABLE fact_repayment FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(Account_ID, Total_Pymnt, @dummy, Total_Rec_Prncp, @dummy, Total_Rrec_int, Is_Delinquent_Loan, Is_Default_Loan, @dummy, Repayment_Behavior);
```

### 6. Post-Load Fixes

```sql
-- Remove any blank row in dim_branch
DELETE FROM dim_branch WHERE Branch_ID IS NULL;

-- Fix carriage return (\r) hidden in text columns due to Windows CSV line endings
SET SQL_SAFE_UPDATES = 0;
UPDATE fact_repayment SET Repayment_Behavior  = TRIM(BOTH '\r' FROM Repayment_Behavior);
UPDATE fact_repayment SET Is_Delinquent_Loan  = TRIM(BOTH '\r' FROM Is_Delinquent_Loan);
UPDATE fact_repayment SET Is_Default_Loan     = TRIM(BOTH '\r' FROM Is_Default_Loan);
SET SQL_SAFE_UPDATES = 1;
```

> **Why the `\r` fix?** Windows saves CSVs with `\r\n` line endings. MySQL's `LINES TERMINATED BY '\n'` strips `\n` but leaves `\r` attached to the last column value of each row. This causes `WHERE Repayment_Behavior = 'On-Time'` to return 0 rows even though the values appear correct. `TRIM(BOTH '\r' FROM col)` removes it.

### 7. Verify Load

```sql
SELECT COUNT(*) FROM dim_client;    -- Expected: 1000
SELECT COUNT(*) FROM dim_branch;    -- Expected: 180
SELECT COUNT(*) FROM dim_product;   -- Expected: 11
SELECT COUNT(*) FROM fact_loan;     -- Expected: 2000
SELECT COUNT(*) FROM fact_repayment; -- Expected: 2000
```

---

## KPI Reference

### KPI 1: Total Clients

**Business Question:** How many unique clients exist in the system?

```sql
DROP TABLE IF EXISTS kpi_01_total_clients;
CREATE TABLE kpi_01_total_clients AS
SELECT COUNT(*) AS Total_Clients FROM dim_client;
```

**Insight:** The baseline headcount of the entire client base. Used as the denominator for client-level ratios and segmentation.

---

### KPI 2: Active Clients

**Business Question:** How many clients currently have at least one active loan?

```sql
DROP TABLE IF EXISTS kpi_02_active_clients;
CREATE TABLE kpi_02_active_clients AS
SELECT COUNT(DISTINCT Client_id) AS Active_Clients
FROM fact_loan
WHERE Loan_Status = 'Active';
```

**Insight:** Measures current portfolio engagement. A declining active client count signals loan book contraction.

---

### KPI 3: New Clients

**Business Question:** How many clients have ever taken a loan (all-time unique borrowers)?

```sql
DROP TABLE IF EXISTS kpi_03_new_clients;
CREATE TABLE kpi_03_new_clients AS
SELECT COUNT(Client_id) AS New_Clients
FROM (
    SELECT Client_id FROM fact_loan GROUP BY Client_id
) AS All_Time_New_Clients;
```

**Insight:** Counts every unique client who has received at least one disbursement. Reflects total client acquisition across the full period.

---

### KPI 4: Client Retention Rate

**Business Question:** Compared to the previous year, how many distinct clients are being served this year?

```sql
DROP TABLE IF EXISTS kpi_04_client_retention_rate;
CREATE TABLE kpi_04_client_retention_rate AS
SELECT
    curr.curr_clients,
    prev.prev_clients,
    ROUND((curr.curr_clients / NULLIF(prev.prev_clients, 0)) * 100, 2) AS Client_Retention_Rate_Pct
FROM
    (SELECT COUNT(DISTINCT Client_id) AS curr_clients FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan)) AS curr,
    (SELECT COUNT(DISTINCT Client_id) AS prev_clients FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan) - 1) AS prev;
```

**Insight:** Mirrors the DAX formula `DIVIDE(DISTINCTCOUNT current year, DISTINCTCOUNT previous year)`. A value above 100% means the institution is serving more clients than the prior year. Computed dynamically using `MAX(YEAR)` so it always compares the two most recent years without hardcoding.

> **Note:** If your Excel dashboard shows a different value, it is because a year slicer is active filtering to a specific period. The SQL computes the unfiltered all-data result.

---

### KPI 5: Total Loan Amount Disbursed

**Business Question:** What is the total value of all loans sanctioned?

```sql
DROP TABLE IF EXISTS kpi_05_total_loan_amount;
CREATE TABLE kpi_05_total_loan_amount AS
SELECT SUM(Loan_Amount) AS Total_Loan_Amount FROM fact_loan;
```

**Insight:** The gross loan book size. The primary measure of portfolio scale.

---

### KPI 6: Total Funded Amount

**Business Question:** What is the total amount actually disbursed to borrowers?

```sql
DROP TABLE IF EXISTS kpi_06_total_funded_amount;
CREATE TABLE kpi_06_total_funded_amount AS
SELECT SUM(Funded_Amount) AS Total_Funded_Amount FROM fact_loan;
```

**Insight:** Funded Amount is typically slightly less than Loan Amount due to processing fees or partial disbursements. The gap between KPI 5 and KPI 6 indicates funding leakage.

---

### KPI 7: Average Loan Size

**Business Question:** What is the typical loan amount per borrower?

```sql
DROP TABLE IF EXISTS kpi_07_average_loan_size;
CREATE TABLE kpi_07_average_loan_size AS
SELECT AVG(Loan_Amount) AS Avg_Loan_Size FROM fact_loan;
```

**Insight:** Tracks whether the institution is moving upmarket (larger loans) or downmarket over time. Useful for product strategy and risk appetite decisions.

---

### KPI 8: Loan Growth %

**Business Question:** How has total loan disbursement changed compared to the previous year?

```sql
DROP TABLE IF EXISTS kpi_08_loan_growth;
CREATE TABLE kpi_08_loan_growth AS
SELECT
    curr.curr_amt,
    prev.prev_amt,
    ROUND(((curr.curr_amt - prev.prev_amt) / NULLIF(prev.prev_amt, 0)) * 100, 2) AS Loan_Growth_Pct
FROM
    (SELECT SUM(Loan_Amount) AS curr_amt FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan)) AS curr,
    (SELECT SUM(Loan_Amount) AS prev_amt FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan) - 1) AS prev;
```

**Insight:** Mirrors the DAX formula `DIVIDE(CurrAmt - PrevAmt, PrevAmt)`. Positive growth signals business expansion; negative growth requires investigation into disbursement slowdown or portfolio runoff. Dynamically uses the two most recent years.

---

### KPI 9: Total Repayments Collected

**Business Question:** How much money has been collected from borrowers in total?

```sql
DROP TABLE IF EXISTS kpi_09_total_repayments;
CREATE TABLE kpi_09_total_repayments AS
SELECT SUM(Total_Pymnt) AS Total_Repayments FROM fact_repayment;
```

**Insight:** The gross cash inflow from the loan portfolio. Comparing this with KPI 5 shows the overall collection efficiency of the institution.

---

### KPI 10: Principal Recovery Rate

**Business Question:** What percentage of disbursed principal has been recovered?

```sql
DROP TABLE IF EXISTS kpi_10_principal_recovery;
CREATE TABLE kpi_10_principal_recovery AS
SELECT
    (SUM(r.Total_Rec_Prncp) / NULLIF(SUM(l.Loan_Amount), 0)) * 100 AS Principal_Recovery_Rate_Pct
FROM fact_repayment r
JOIN fact_loan l ON r.Account_ID = l.Account_ID;
```

**Insight:** A rate below 100% signals outstanding balances or write-offs. Joined on `Account_ID` to correctly pair each repayment with its loan amount. `NULLIF` prevents division by zero.

---

### KPI 11: Interest Income

**Business Question:** How much interest revenue has the institution earned?

```sql
DROP TABLE IF EXISTS kpi_11_interest_income;
CREATE TABLE kpi_11_interest_income AS
SELECT SUM(Total_Rrec_int) AS Interest_Income FROM fact_repayment;
```

**Insight:** The primary revenue line for a lending institution. Combined with KPI 17 (product profitability), this reveals which products are the most profitable income drivers.

---

### KPI 12: Default Rate

**Business Question:** What percentage of loans have defaulted?

```sql
DROP TABLE IF EXISTS kpi_12_default_rate;
CREATE TABLE kpi_12_default_rate AS
SELECT
    (SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Default_Rate_Pct
FROM fact_repayment;
```

**Insight:** 100 out of 2,000 loans = 5% default rate. A critical risk metric. Rising default rates signal deteriorating credit quality or economic stress in the borrower base.

> **Important:** The `\r` trim fix in post-load setup must be applied first, otherwise `Is_Default_Loan = 'Y'` returns 0 due to hidden carriage return characters.

---

### KPI 13: Delinquency Rate

**Business Question:** What percentage of loans are currently delinquent (overdue but not yet defaulted)?

```sql
DROP TABLE IF EXISTS kpi_13_delinquency_rate;
CREATE TABLE kpi_13_delinquency_rate AS
SELECT
    (SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Delinquency_Rate_Pct
FROM fact_repayment;
```

**Insight:** 207 out of 2,000 loans = 10.35% delinquency rate. Delinquency is a leading indicator of future defaults — a high rate signals collections intervention is needed before loans roll to default status.

---

### KPI 14: On-Time Repayment %

**Business Question:** What proportion of borrowers are repaying on schedule?

```sql
DROP TABLE IF EXISTS kpi_14_ontime_repayment;
CREATE TABLE kpi_14_ontime_repayment AS
SELECT
    SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) AS OnTime_Count,
    COUNT(*) AS Total_Repayments,
    ROUND(SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS On_Time_Repayment_Pct
FROM fact_repayment;
```

**Insight:** 1,421 of 2,000 = 71.05% on-time rate. The complement of delinquency and default. High on-time repayment reflects strong underwriting quality and borrower financial health.

> **Troubleshooting:** If this returns 0%, run `SELECT HEX(Repayment_Behavior) FROM fact_repayment LIMIT 1;` — if the hex ends in `0D`, your CSV has Windows `\r\n` line endings. Apply the `\r` trim fix from the post-load setup section.

---

### KPI 15: Loan Distribution by Branch

**Business Question:** Which branches are disbursing the most loan value?

```sql
DROP TABLE IF EXISTS kpi_15_loan_by_branch;
CREATE TABLE kpi_15_loan_by_branch AS
SELECT
    b.Branch_Name,
    b.Branch_Performance_Category,
    SUM(l.Loan_Amount) AS Total_Loan_Amount
FROM fact_loan l
JOIN dim_branch b ON l.Branch_ID = b.Branch_ID
GROUP BY b.Branch_Name, b.Branch_Performance_Category
ORDER BY Total_Loan_Amount DESC;
```

**Insight:** Ranks every branch by total loan volume. Joined on `Branch_ID` (the unique key) rather than `Branch_Name` to avoid incorrect matches where multiple branches share a city name.

> **Setup note:** The original `dim_branch` load script skipped `Branch_Name`. This was fixed by dropping the foreign key constraint on `fact_loan`, reloading `dim_branch` with `Branch_Name` in the correct column position, and re-adding the constraint.

---

### KPI 16: Product-wise Loan Volume

**Business Question:** Which loan products are generating the most disbursement volume?

```sql
DROP TABLE IF EXISTS kpi_16_product_loan_volume;
CREATE TABLE kpi_16_product_loan_volume AS
SELECT p.Purpose_Category, SUM(l.Loan_Amount) AS Product_Loan_Volume
FROM fact_loan l
JOIN dim_product p ON l.Product_Id = p.Product_Id
GROUP BY p.Purpose_Category;
```

**Insight:** Breaks down the loan book by purpose — Services, Agriculture, Education, Home Loan, Trade, Property, Car Loan, Factory. Shows which product lines drive volume and informs where to scale or cut back.

---

### KPI 17: Product Profitability

**Business Question:** Which loan products are generating the most interest income?

```sql
DROP TABLE IF EXISTS kpi_17_product_profitability;
CREATE TABLE kpi_17_product_profitability AS
SELECT p.Purpose_Category, SUM(r.Total_Rrec_int) AS Product_Profitability
FROM fact_loan l
JOIN fact_repayment r ON l.Account_ID = r.Account_ID
JOIN dim_product p ON l.Product_Id = p.Product_Id
GROUP BY p.Purpose_Category;
```

**Insight:** A three-table join linking repayment interest back to the product dimension. High-volume products (KPI 16) are not always the most profitable — interest rates differ by product and grade. This KPI reveals the true revenue contribution per product line.

---

## Key SQL Concepts Used

| Concept | Where Used |
|---|---|
| `FOREIGN KEY` constraints | Table definitions — enforces referential integrity across all 5 tables |
| `LOAD DATA INFILE` with `@dummy` | Data loading — skips irrelevant source columns selectively |
| `STR_TO_DATE` + `SUBSTRING` | fact_loan load — converts raw datetime string to DATE |
| `TRIM(BOTH '\r' FROM col)` | Post-load fix — removes hidden Windows carriage returns from text columns |
| `COUNT(DISTINCT ...)` | KPIs 2, 4 — counts unique clients, not duplicate rows |
| `CASE WHEN ... THEN 1 ELSE 0` | KPIs 12, 13, 14 — conditional counting for flag columns |
| `NULLIF` | KPIs 4, 8, 10 — division-by-zero guard |
| Subquery-based dynamic year | KPIs 4, 8 — always compares the two most recent years without hardcoding |
| Multi-table `JOIN` | KPIs 10, 15, 16, 17 — links fact and dimension tables |
| `CREATE TABLE AS SELECT` | All KPIs — stores query results as persistent tables |

---

## Notes

**Star Schema Design**
The dataset follows a classic star schema: one central fact table (`fact_loan`) surrounded by three dimension tables (`dim_client`, `dim_branch`, `dim_product`) and one related fact table (`fact_repayment`). This design separates descriptive attributes from transactional measures, enabling clean joins and efficient aggregation.

**Foreign Key Constraint Management**
When `dim_branch` needed to be reloaded to fix the missing `Branch_Name` column, the foreign key on `fact_loan` had to be dropped first (`ALTER TABLE fact_loan DROP FOREIGN KEY fact_loan_ibfk_2`), then the table was recreated and reloaded, and the data relationship was preserved through the join in KPI 15.

**Windows CSV Line Ending Issue**
CSVs saved from Excel on Windows use `\r\n` line endings. MySQL's `LINES TERMINATED BY '\n'` strips `\n` but leaves `\r` on the last column of each row. This silently corrupts text comparisons. Always run `HEX()` to diagnose invisible character issues before concluding a query is logically wrong.

**Dynamic Year Comparisons (KPIs 4 & 8)**
Rather than hardcoding years like `WHERE YEAR(...) = 2023`, both KPIs use `(SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan)` as the current year. This makes the queries future-proof as new data is added, they automatically compare the two most recent years.

**`@dummy` Variable Pattern in LOAD DATA**
MySQL's `LOAD DATA INFILE` requires all columns in the CSV to be accounted for. Columns not needed are assigned to `@dummy` (a throwaway variable) rather than a table column, so they are silently discarded. This is how selective column loading is achieved without modifying the source CSV.

---

## Summary Table of KPIs

| # | KPI Name | Output Type | Primary Use Case |
|---|---|---|---|
| 1 | Total Clients | Scalar | Client base size |
| 2 | Active Clients | Scalar | Current portfolio engagement |
| 3 | New Clients | Scalar | Total client acquisition |
| 4 | Client Retention Rate | Scalar (%) | Year-over-year client growth |
| 5 | Total Loan Amount Disbursed | Scalar | Portfolio scale |
| 6 | Total Funded Amount | Scalar | Actual disbursement vs sanction |
| 7 | Average Loan Size | Scalar | Product positioning |
| 8 | Loan Growth % | Scalar (%) | Year-over-year business growth |
| 9 | Total Repayments Collected | Scalar | Cash inflow from portfolio |
| 10 | Principal Recovery Rate | Scalar (%) | Collection efficiency |
| 11 | Interest Income | Scalar | Revenue from lending |
| 12 | Default Rate | Scalar (%) | Credit risk — loss events |
| 13 | Delinquency Rate | Scalar (%) | Credit risk — early warning |
| 14 | On-Time Repayment % | Scalar (%) | Borrower repayment quality |
| 15 | Loan Distribution by Branch | Ranked table | Branch performance comparison |
| 16 | Product-wise Loan Volume | Ranked table | Product line analysis |
| 17 | Product Profitability | Ranked table | Revenue by product line |

# Bank Debit and Credit: SQL Project

A end-to-end SQL analytics project that ingests bank transaction data, stores it in a relational database, and computes 13 business KPIs covering transaction volumes, branch performance, risk detection, and growth trends.

---

## Database Setup

**Database:** `bank_db`  
**Table:** `debitcredit`  
**Engine:** MySQL (uses `LOAD DATA INFILE`, `DATE_FORMAT`, `PERCENT_RANK`, window functions)

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
| Total Records         | ~100,000 transactions                                               |
| Currency              | INR (Indian Rupee)                                                  |
| Banks Covered         | Axis Bank, HDFC Bank, ICICI Bank, Kotak Mahindra Bank, State Bank of India, Punjab National Bank |
| Branches              | Main Branch, City Center Branch, North Branch, East Branch, Suburban Branch, Downtown Branch |
| Transaction Types     | Credit, Debit                                                       |
| Payment Methods       | Credit Card, Debit Card, Bank Transfer                              |
| Transaction Categories | Salary Deposit, Bonus Payment, Client Payment, Freelance Payment, Online Shopping, Grocery Shopping, Utility Bill Payment, Refund from Retailer, Refund for Overcharge, Dinner at Restaurant |

---

## Setup Instructions

### 1. Prerequisites
- MySQL Server 8.0+
- MySQL Workbench or any MySQL client

### 2. Create Database and Table

```sql
CREATE DATABASE IF NOT EXISTS bank_db;
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
```

### 3. Load Data

Copy your CSV into MySQL's secure upload folder, then run:

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/debitcredit.csv'
INTO TABLE debitcredit
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

> **Note:** `secure_file_priv` must point to the folder containing the CSV. Run `SHOW VARIABLES LIKE 'secure_file_priv';` to find your path.

### 4. Verify Load

```sql
SELECT COUNT(*) FROM debitcredit;
-- Expected: 100000 rows
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

**Insight:** Identifies peak and off-peak periods. Useful for staffing, server capacity planning, and targeted marketing campaigns.

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

**Insight:** Shows customer payment behaviour. Informs product and infrastructure decisions.

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

**Insight:** Uses the `LAG()` window function to compare each month against the prior month per branch. A negative `MoM_Growth_Percentage` flags a branch that needs investigation.

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

**Insight:** Dynamically identifies the top 5% of transactions by amount using `PERCENT_RANK()`. Unlike a hardcoded threshold, this adapts automatically as the data grows.

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

**Insight:** Provides a single headline count of high-risk transactions. By definition, this should be approximately 5% of total transaction count.

---

### KPI 13: Total Transactions

**Business Question:** How many transactions have been recorded in total?

```sql
SELECT COUNT(*) AS Total_Transactions
FROM debitcredit;
```

**Insight:** The most fundamental metric — the total number of records in the dataset. Used as the baseline denominator for distribution and ratio KPIs (e.g., KPI 9, KPI 12).

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
| `COUNT(*)`                  | KPI 13 — total record count |

---

## Notes

**Excel Serial Date Conversion**
All dates in the dataset are stored as Excel serial integers. The formula `DATE_ADD('1899-12-30', INTERVAL transaction_date DAY)` is the correct MySQL equivalent of Excel's date origin.

**Dynamic vs. Static Thresholds (KPIs 11 & 12)**
The high-risk cutoff uses `PERCENT_RANK()` rather than a hardcoded number. This means the threshold automatically adjusts as new data is added — making it production-safe without manual recalibration.

**`NULLIF` Pattern**
Wherever division occurs (KPIs 3, 5, 10), `NULLIF(denominator, 0)` is used to return `NULL` instead of throwing a division-by-zero error.

---

## Summary Table of KPIs

| #  | KPI Name                        | Output Type      | Primary Use Case              |
|----|---------------------------------|------------------|-------------------------------|
| 1  | Total Credit Amount             | Scalar           | Financial overview            |
| 2  | Total Debit Amount              | Scalar           | Financial overview            |
| 3  | Credit to Debit Ratio           | Scalar           | Fund flow health              |
| 4  | Net Transaction Amount          | Scalar           | Net fund position             |
| 5  | Account Activity Ratio          | Scalar           | Customer engagement           |
| 6  | Transactions Per Day/Week/Month | Time series      | Trend & seasonality analysis  |
| 7  | Total Amount by Branch          | Ranked table     | Branch performance            |
| 8  | Volume by Bank                  | Ranked table     | Partner bank comparison       |
| 9  | Payment Method Distribution     | Distribution (%) | Customer behaviour insights   |
| 10 | Branch MoM Growth               | Time series      | Growth tracking & alerts      |
| 11 | High-Risk Transaction Flags     | Flagged records  | Fraud / AML monitoring        |
| 12 | Suspicious Transaction Count    | Scalar           | Risk dashboard headline KPI   |
| 13 | Total Transactions              | Scalar           | Baseline record count         |