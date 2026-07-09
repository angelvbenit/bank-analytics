-- Create and switch to the database
CREATE DATABASE IF NOT EXISTS bank_db;
USE bank_db;

USE bank_db;

-- 1. Dim Client
CREATE TABLE dim_client (
    Client_id INT PRIMARY KEY,
    Client_Name VARCHAR(255),
    Credit_Score INT
);

-- 2. Dim Branch
CREATE TABLE dim_branch (
    Branch_ID VARCHAR(100) PRIMARY KEY,
    Branch_Name VARCHAR(100),
    Branch_Performance_Category VARCHAR(50)
);

-- 3. Dim Product
CREATE TABLE dim_product (
    Product_Id VARCHAR(50) PRIMARY KEY,
    Purpose_Category VARCHAR(100)
);

-- 4. Fact Loan (The Center)
CREATE TABLE fact_loan (
    Account_ID VARCHAR(50) PRIMARY KEY,
    Client_id INT,
    Branch_ID VARCHAR(100),
    Product_Id VARCHAR(50),
    Loan_Amount DECIMAL(15,2),
    Funded_Amount DECIMAL(15,2),
    Disbursement_Date DATE,
    Loan_Status VARCHAR(50),
    FOREIGN KEY (Client_id) REFERENCES dim_client(Client_id),
    FOREIGN KEY (Branch_ID) REFERENCES dim_branch(Branch_ID),
    FOREIGN KEY (Product_Id) REFERENCES dim_product(Product_Id)
);

-- 5. Fact Repayment
CREATE TABLE fact_repayment (
    Account_ID VARCHAR(50) PRIMARY KEY,
    Total_Pymnt DECIMAL(15,2),
    Total_Rec_Prncp DECIMAL(15,2),
    Total_Rrec_int DECIMAL(15,2),
    Is_Delinquent_Loan VARCHAR(5),
    Is_Default_Loan VARCHAR(5),
    Repayment_Behavior VARCHAR(50),
    FOREIGN KEY (Account_ID) REFERENCES fact_loan(Account_ID)
);

-- Load Clients
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_client.csv'
INTO TABLE dim_client FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(Client_id, Client_Name, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, Credit_Score);

-- Load Branches
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_branch.csv'
INTO TABLE dim_branch FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, Branch_Performance_Category, Branch_ID);

-- Load Products
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_product.csv'
INTO TABLE dim_product FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(Product_Id, @dummy, Purpose_Category, @dummy, @dummy, @dummy, @dummy);

-- Load Fact Loan
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_loan.csv'
INTO TABLE fact_loan FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(Account_ID, Client_id, @dummy, Product_Id, Loan_Amount, Funded_Amount, @dummy, @raw_date, Loan_Status, @dummy, @dummy, Branch_ID)
SET Disbursement_Date = STR_TO_DATE(SUBSTRING(@raw_date, 1, 10), '%Y-%m-%d');

-- Load Fact Repayment
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_repayment.csv'
INTO TABLE fact_repayment FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(Account_ID, Total_Pymnt, @dummy, Total_Rec_Prncp, @dummy, Total_Rrec_int, Is_Delinquent_Loan, Is_Default_Loan, @dummy, Repayment_Behavior);

-- check number of rows --

SELECT COUNT(*) FROM fact_loan;

SELECT f.Account_ID 
FROM fact_loan f
LEFT JOIN dim_client c ON f.Client_id = c.Client_id
WHERE c.Client_id IS NULL;

USE bank_db;

-- Step 1: drop the foreign key constraint from fact_loan first
ALTER TABLE fact_loan DROP FOREIGN KEY fact_loan_ibfk_2;

-- Step 2: now drop and recreate dim_branch
DROP TABLE IF EXISTS dim_branch;
CREATE TABLE dim_branch (
    Branch_ID                    VARCHAR(100) PRIMARY KEY,
    Branch_Name                  VARCHAR(100),
    Branch_Performance_Category  VARCHAR(50)
);

-- Step 3: reload with Branch_Name included
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_branch.csv'
INTO TABLE dim_branch
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Branch_Name, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, Branch_Performance_Category, Branch_ID);

-- Step 4: verify
SELECT * FROM dim_branch LIMIT 3;

DELETE FROM dim_branch WHERE Branch_ID IS NULL;

USE bank_db;

USE bank_db;

-- =========================================================
-- KPI TABLES
-- =========================================================

-- 1. Total Clients
DROP TABLE IF EXISTS kpi01_clients;
CREATE TABLE kpi01_clients AS
SELECT COUNT(*) AS Total_Clients
FROM dim_client;
SELECT * FROM kpi01_clients;

-- 2. Active Clients
DROP TABLE IF EXISTS kpi02_active;
CREATE TABLE kpi02_active AS
SELECT COUNT(DISTINCT Client_id) AS Active_Clients
FROM fact_loan
WHERE Loan_Status = 'Active';
SELECT * FROM kpi02_active;

-- 3. New Clients (All-Time)
DROP TABLE IF EXISTS kpi03_new;
CREATE TABLE kpi03_new AS
SELECT COUNT(Client_id) AS New_Clients
FROM (
    SELECT Client_id
    FROM fact_loan
    GROUP BY Client_id
) AS All_Time_New_Clients;
SELECT * FROM kpi03_new;

-- 4. Client Retention Rate (%)
DROP TABLE IF EXISTS kpi04_retention;
CREATE TABLE kpi04_retention AS
SELECT
    curr.curr_clients,
    prev.prev_clients,
    CONCAT(ROUND((curr.curr_clients / NULLIF(prev.prev_clients, 0)) * 100, 2), '%') AS Client_Retention_Rate
FROM
    (SELECT COUNT(DISTINCT Client_id) AS curr_clients
     FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan)) AS curr,
    (SELECT COUNT(DISTINCT Client_id) AS prev_clients
     FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan) - 1) AS prev;
SELECT * FROM kpi04_retention;

-- 5. Total Loan Amount Disbursed (Millions)
DROP TABLE IF EXISTS kpi05_loan_amt;
CREATE TABLE kpi05_loan_amt AS
SELECT CONCAT(ROUND(SUM(Loan_Amount) / 1000000, 2), 'M') AS Total_Loan_Amount
FROM fact_loan;
SELECT * FROM kpi05_loan_amt;
 
-- 6. Total Funded Amount (Millions)
DROP TABLE IF EXISTS kpi06_funded_amt;
CREATE TABLE kpi06_funded_amt AS
SELECT CONCAT(ROUND(SUM(Funded_Amount) / 1000000, 2), 'M') AS Total_Funded_Amount
FROM fact_loan;
SELECT * FROM kpi06_funded_amt;
 
-- 7. Average Loan Size (Thousands)
DROP TABLE IF EXISTS kpi07_avg_loan;
CREATE TABLE kpi07_avg_loan AS
SELECT CONCAT(ROUND(AVG(Loan_Amount) / 1000, 2), 'K') AS Avg_Loan_Size
FROM fact_loan;
SELECT * FROM kpi07_avg_loan;
 
-- 8. Loan Growth % (curr/prev in Millions, growth as %)
DROP TABLE IF EXISTS kpi08_growth;
CREATE TABLE kpi08_growth AS
SELECT
    CONCAT(ROUND(curr.curr_amt / 1000000, 2), 'M') AS Curr_Amount,
    CONCAT(ROUND(prev.prev_amt / 1000000, 2), 'M') AS Prev_Amount,
    CONCAT(ROUND(((curr.curr_amt - prev.prev_amt) / NULLIF(prev.prev_amt, 0)) * 100, 2), '%') AS Loan_Growth
FROM
    (SELECT SUM(Loan_Amount) AS curr_amt
     FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan)) AS curr,
    (SELECT SUM(Loan_Amount) AS prev_amt
     FROM fact_loan
     WHERE YEAR(Disbursement_Date) = (SELECT MAX(YEAR(Disbursement_Date)) FROM fact_loan) - 1) AS prev;
SELECT * FROM kpi08_growth;
 
-- 9. Total Repayments Collected (Millions)
DROP TABLE IF EXISTS kpi09_repay;
CREATE TABLE kpi09_repay AS
SELECT CONCAT(ROUND(SUM(Total_Pymnt) / 1000000, 2), 'M') AS Total_Repayments
FROM fact_repayment;
SELECT * FROM kpi09_repay;
 
-- 10. Principal Recovery Rate (%)
DROP TABLE IF EXISTS kpi10_recovery;
CREATE TABLE kpi10_recovery AS
SELECT CONCAT(ROUND((SUM(r.Total_Rec_Prncp) / NULLIF(SUM(l.Loan_Amount), 0)) * 100, 2), '%') AS Principal_Recovery_Rate
FROM fact_repayment r
JOIN fact_loan l ON r.Account_ID = l.Account_ID;
SELECT * FROM kpi10_recovery;
 
-- 11. Interest Income (Millions)
DROP TABLE IF EXISTS kpi11_interest;
CREATE TABLE kpi11_interest AS
SELECT CONCAT(ROUND(SUM(Total_Rrec_int) / 1000000, 2), 'M') AS Interest_Income
FROM fact_repayment;
SELECT * FROM kpi11_interest;
 
-- 12. Default Rate (%)
DROP TABLE IF EXISTS kpi12_default;
CREATE TABLE kpi12_default AS
SELECT CONCAT(ROUND((SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2), '%') AS Default_Rate
FROM fact_repayment;
SELECT * FROM kpi12_default;
 
-- 13. Delinquency Rate (%)
DROP TABLE IF EXISTS kpi13_delinq;
CREATE TABLE kpi13_delinq AS
SELECT CONCAT(ROUND((SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2), '%') AS Delinquency_Rate
FROM fact_repayment;
SELECT * FROM kpi13_delinq;
 
-- 14. On-Time Repayment % 
DROP TABLE IF EXISTS kpi14_ontime;
CREATE TABLE kpi14_ontime AS
SELECT
    SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) AS OnTime_Count,
    COUNT(*) AS Total_Repayments,
    CONCAT(ROUND(SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2), '%') AS On_Time_Repayment
FROM fact_repayment;
SELECT * FROM kpi14_ontime;
 
-- 15. Loan by Branch (Millions)
DROP TABLE IF EXISTS kpi15_branch;
CREATE TABLE kpi15_branch AS
SELECT
    b.Branch_Name,
    b.Branch_Performance_Category,
    CONCAT(ROUND(SUM(l.Loan_Amount) / 1000000, 2), 'M') AS Total_Loan_Amount
FROM fact_loan l
JOIN dim_branch b ON l.Branch_ID = b.Branch_ID
GROUP BY b.Branch_Name, b.Branch_Performance_Category
ORDER BY SUM(l.Loan_Amount) DESC;
SELECT * FROM kpi15_branch;
 
-- 16. Product Loan Volume (Millions)
DROP TABLE IF EXISTS kpi16_prod_vol;
CREATE TABLE kpi16_prod_vol AS
SELECT p.Purpose_Category, CONCAT(ROUND(SUM(l.Loan_Amount) / 1000000, 2), 'M') AS Product_Loan_Volume
FROM fact_loan l
JOIN dim_product p ON l.Product_Id = p.Product_Id
GROUP BY p.Purpose_Category;
SELECT * FROM kpi16_prod_vol;
 
-- 17. Product Profitability (Millions)
DROP TABLE IF EXISTS kpi17_prod_profit;
CREATE TABLE kpi17_prod_profit AS
SELECT p.Purpose_Category, CONCAT(ROUND(SUM(r.Total_Rrec_int) / 1000000, 2), 'M') AS Product_Profitability
FROM fact_loan l
JOIN fact_repayment r ON l.Account_ID = r.Account_ID
JOIN dim_product p ON l.Product_Id = p.Product_Id
GROUP BY p.Purpose_Category;
SELECT * FROM kpi17_prod_profit;