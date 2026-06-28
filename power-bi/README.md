# Bank Debit Credit Dashboard: Power BI Project

> An end-to-end business intelligence solution for banking transaction analytics, built on a MySQL backend with a fully dynamic, slicer-driven Power BI frontend powered entirely by DAX.

## Dashboard Preview

### Overview
![Overview](https://raw.githubusercontent.com/angelvbenit/bank-analytics/main/power-bi/01_overview.jpg)

### Branch & Bank Analysis
![Branch & Bank Analysis](https://raw.githubusercontent.com/angelvbenit/bank-analytics/main/power-bi/02_branch-bank.jpg)

### Risk Intelligence
![Risk Intelligence](https://raw.githubusercontent.com/angelvbenit/bank-analytics/main/power-bi/03_risk.jpg)

### Live Demo
![Dashboard Walkthrough](https://raw.githubusercontent.com/angelvbenit/bank-analytics/main/power-bi/bank-analytics-powerbi.gif)

---

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Project Architecture](#project-architecture)
4. [Database Setup (MySQL)](#database-setup-mysql)
   - [Creating the Database](#creating-the-database)
   - [Creating & Loading the `debitcredit` Table](#creating--loading-the-debitcredit-table)
   - [Schema Definition](#schema-definition)
5. [Connecting MySQL to Power BI via ODBC](#connecting-mysql-to-power-bi-via-odbc)
   - [Installing the MySQL ODBC Connector](#installing-the-mysql-odbc-connector)
   - [Configuring the ODBC Data Source](#configuring-the-odbc-data-source)
   - [Loading Tables into Power BI](#loading-tables-into-power-bi)
6. [Data Modeling in Power BI](#data-modeling-in-power-bi)
   - [Calendar Table (DAX)](#calendar-table-dax)
   - [Calculated Columns on `debitcredit`](#calculated-columns-on-debitcredit)
   - [Calculated Columns on Supporting Tables](#calculated-columns-on-supporting-tables)
7. [DAX Measures — Core KPIs](#dax-measures--core-kpis)
   - [KPI 1 — Total Credit](#kpi-1--total-credit)
   - [KPI 2 — Total Debit](#kpi-2--total-debit)
   - [KPI 3 — Net Transaction Amount](#kpi-3--net-transaction-amount)
   - [KPI 4 — Credit-to-Debit Ratio](#kpi-4--credit-to-debit-ratio)
   - [KPI 5 — Total Transactions](#kpi-5--total-transactions)
   - [KPI 6 — Total Amount (All Transactions)](#kpi-6--total-amount-all-transactions)
   - [KPI 7 — Risk Threshold (95th Percentile)](#kpi-7--risk-threshold-95th-percentile)
   - [KPI 8 — Suspicious Transactions Count](#kpi-8--suspicious-transactions-count)
   - [KPI 9 — Risk Rate %](#kpi-9--risk-rate-)
8. [Risk Intelligence Layer](#risk-intelligence-layer)
   - [Dynamic Risk Flagging Column](#dynamic-risk-flagging-column)
   - [High-Risk Transaction Logic](#high-risk-transaction-logic)
9. [Data Transformation & Enrichment Columns](#data-transformation--enrichment-columns)
   - [Date Handling](#date-handling)
   - [Customer ID Shortening](#customer-id-shortening)
   - [Display Labels for Time Series](#display-labels-for-time-series)
   - [Month-over-Month Growth Display](#month-over-month-growth-display)
10. [Dashboard Visuals & Charts](#dashboard-visuals--charts)
    - [KPI Cards](#kpi-cards)
    - [Transaction Volume Over Time](#transaction-volume-over-time)
    - [Total Amount by Branch (Bar Chart)](#total-amount-by-branch-bar-chart)
    - [Transaction Volume by Bank](#transaction-volume-by-bank)
    - [Transaction Method Distribution](#transaction-method-distribution)
    - [Branch Month-over-Month Growth](#branch-month-over-month-growth)
    - [High-Risk Transactions Table](#high-risk-transactions-table)
11. [Making the Dashboard Fully Dynamic](#making-the-dashboard-fully-dynamic)
12. [File & Folder Structure](#file--folder-structure)
13. [Known Gotchas & How They Were Solved](#known-gotchas--how-they-were-solved)
14. [Future Enhancements](#future-enhancements)

---

## Project Overview

This project is a **fully interactive banking analytics dashboard** built in Microsoft Power BI, with data sourced from a **MySQL 8.0 database**. The raw transaction dataset — containing customer debit and credit activity across multiple branches, banks, and transaction methods — was imported into MySQL, and the core `debitcredit` table was connected directly to Power BI via an ODBC driver.

All KPI calculations, risk scoring, time intelligence, and aggregations are powered by **DAX (Data Analysis Expressions)** measures and calculated columns written natively inside Power BI. This design ensures every chart, card, and table on the dashboard **responds dynamically** to slicers — filtering by date, branch, bank, transaction type, transaction method, or any other dimension updates every visual simultaneously and instantly.

The dashboard answers key business questions for banking operations teams:

- How much has been credited vs debited in any given period or branch?
- What is the net flow of money and the credit-to-debit health ratio?
- Which branches and banks are driving the most transaction volume?
- How are customers transacting — by method, by time of day, by week?
- Which transactions are statistically high-risk and what percentage of total activity do they represent?
- How is branch-level transaction volume trending month over month?

---

## Tech Stack

| Layer | Tool / Technology |
|---|---|
| **Database** | MySQL 8.0 |
| **Connectivity** | MySQL ODBC 8.x Unicode Driver |
| **BI & Visualisation** | Microsoft Power BI Desktop |
| **Query Language (DB)** | SQL (DDL + DML + Window Functions + CTEs) |
| **Query Language (BI)** | DAX (Data Analysis Expressions) |
| **Data Format (Source)** | CSV (`debitcredit.csv`) |
| **OS** | Windows (64-bit) |

---

## Project Architecture

```
debitcredit.csv (raw source)
        │
        ▼
┌──────────────────────┐
│   MySQL 8.0          │
│   Database: bank_db  │
│                      │
│  • debitcredit       │  ← core fact table (loaded via LOAD DATA INFILE)
└──────────────────────┘
        │
        │  MySQL ODBC 8.x Unicode Driver
        │  ODBC DSN: bank_db (System DSN)
        ▼
┌──────────────────────────────────────────────────────────┐
│   Power BI Desktop                                       │
│                                                          │
│   Tables loaded:                                         │
│   • debitcredit  (core fact table)                       │
│                                                          │
│   DAX Calculated Tables:                                 │
│   • Calendar  (generated via CALENDAR() function)        │
│                                                          │
│   DAX Calculated Columns:                                │
│   • Proper Date, Date Only, Amount Numeric,              │
│     Short ID, Risk Flag, Date Clean, etc.                │
│                                                          │
│   DAX Measures (KPIs):                                   │
│   • Total Credit, Total Debit, Net Transaction Amount,   │
│     Credit Debit Ratio, Total Transactions,              │
│     Suspicious Transactions, Risk Rate %, Risk Threshold │
│                                                          │
│   Visuals: Cards, Bar Charts, Line Charts,               │
│            Pie/Donut Charts, Tables, Slicers             │
└──────────────────────────────────────────────────────────┘
```

---

## Database Setup (MySQL)

### Creating the Database

The first step is setting up a dedicated database to house all banking transaction data:

```sql
CREATE DATABASE bank_db;
USE bank_db;
```

### Creating & Loading the `debitcredit` Table

The `debitcredit` table is the single source of truth for this entire project. It stores every individual transaction — whether a credit or a debit — along with rich metadata about the customer, account, branch, bank, and transaction method.

```sql
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

> **Note on data types:** All columns are initially stored as `TEXT` to ensure safe ingestion of the raw CSV without type conversion errors. Numeric casting and date parsing are handled downstream in Power BI using DAX calculated columns, keeping the SQL layer clean and idempotent.

The CSV is bulk-loaded using MySQL's high-performance `LOAD DATA INFILE` command:

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/debitcredit.csv'
INTO TABLE debitcredit
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

A quick row count confirms the load was successful:

```sql
SELECT COUNT(*) FROM debitcredit;
```

### Schema Definition

| Column | Type | Description |
|---|---|---|
| `customer_id` | TEXT | Unique UUID-format customer identifier |
| `customer_name` | TEXT | Full name of the account holder |
| `account_number` | TEXT | Bank account number |
| `transaction_date` | TEXT | Excel serial date number (days since 1899-12-30) |
| `transaction_type` | TEXT | `'Credit'` or `'Debit'` |
| `amount` | TEXT | Transaction amount (cast to DECIMAL in Power BI) |
| `balance` | TEXT | Account balance at time of transaction |
| `description` | TEXT | Free-text transaction description or merchant note |
| `branch` | TEXT | Bank branch where the transaction occurred |
| `transaction_method` | TEXT | Method used (e.g. ATM, Online, UPI, NEFT, etc.) |
| `currency` | TEXT | Currency code (e.g. INR, USD) |
| `bank_name` | TEXT | Name of the bank |

---

## Connecting MySQL to Power BI via ODBC

### Installing the MySQL ODBC Connector

Power BI does not natively speak MySQL's wire protocol — a driver layer is needed. The MySQL ODBC Connector bridges this gap.

1. Navigate to: [https://dev.mysql.com/downloads/connector/odbc/](https://dev.mysql.com/downloads/connector/odbc/)
2. Download the **Windows (x86, 64-bit) MSI Installer**
3. Run the installer
4. **Fully close Power BI Desktop** before completing installation
5. Restart the PC to ensure the driver registers correctly in the Windows driver registry

### Configuring the ODBC Data Source

A System DSN (Data Source Name) must be created so that Power BI can discover and authenticate against the MySQL database:

1. Press **Windows + R**, type `odbcad32`, press **Enter** — this opens the ODBC Data Source Administrator
2. Click the **System DSN** tab
3. Click **Add**
4. Select **MySQL ODBC 8.x Unicode Driver**, click **Finish**
5. Fill in the connection details:

| Field | Value |
|---|---|
| Data Source Name | `bank_db` |
| Server | `localhost` |
| Port | `3306` |
| User | `root` |
| Password | *(your MySQL root password)* |
| Database | `bank_db` |

6. Click **Test** — verify "Connection successful"
7. Click **OK** to save

### Loading Tables into Power BI

1. Open **Power BI Desktop**
2. Click **Get Data** → search for **ODBC** → click **Connect**
3. From the DSN dropdown, select **bank_db**
4. Click **OK**
5. Enter credentials: username `root` and MySQL password when prompted
6. The **Navigator** panel opens — select the `debitcredit` table (and any other tables as needed)
7. Click **Load**

Power BI now has a live-connected or imported copy of the `debitcredit` table, which serves as the foundation for all DAX calculations.

---

## Data Modeling in Power BI

### Calendar Table (DAX)

A dedicated Calendar table is essential for time intelligence — it enables correct filtering by year, quarter, month, week, and supports slicers that work across all date-based visuals.

The `transaction_date` column in `debitcredit` stores dates as **Excel serial numbers** (integer count of days since `1899-12-30`). The Calendar table must handle this conversion:

**Go to Modeling → New Table, then paste:**

```dax
Calendar = 
VAR MinDate = MIN(debitcredit[transaction_date]) + 0
VAR MaxDate = MAX(debitcredit[transaction_date]) + 0
RETURN
CALENDAR(
    DATE(1899, 12, 30) + MinDate,
    DATE(1899, 12, 30) + MaxDate
)
```

This generates a contiguous date table spanning the exact date range present in the transaction data. After creating the table, **mark it as a Date Table** (Table Tools → Mark as Date Table → select the `Date` column) so Power BI's time intelligence functions work correctly.

**Additional calculated columns on the Calendar table** (via New Column on the Calendar table):

```dax
Month Name   = FORMAT('Calendar'[Date], "MMM YYYY")
Month Number = MONTH('Calendar'[Date])
Month Short  = FORMAT('Calendar'[Date], "MMM")
Year         = YEAR('Calendar'[Date])
Quarter      = "Q" & QUARTER('Calendar'[Date])
Week Number  = WEEKNUM('Calendar'[Date])
```

These columns power the axis labels and sort order on all time-series charts.

### Calculated Columns on `debitcredit`

Several columns are added to the `debitcredit` table to enrich and clean the raw data:

#### 1. Proper Date — Convert Serial Number to Real Date

```dax
Proper Date = DATE(1899, 12, 30) + VALUE(debitcredit[transaction_date])
```

This resolves the Excel serial date integer into a true Power BI `Date/Time` value, enabling date filters and time intelligence.

#### 2. Date Only — Strip the Time Component

Because `Proper Date` sometimes includes a time component (e.g. `5:55 PM`), a clean date-only column is needed for grouping and filtering by day:

```dax
Date Only = DATE(
    YEAR(debitcredit[Proper Date]),
    MONTH(debitcredit[Proper Date]),
    DAY(debitcredit[Proper Date])
)
```

#### 3. Amount Numeric — Cast Text Amount to Number

Since `amount` was loaded as TEXT, it must be converted to a numeric type before any mathematical DAX measure can use it:

```dax
Amount Numeric = VALUE(debitcredit[amount])
```

All KPI measures reference `Amount Numeric`, never the raw `amount` column.

#### 4. Short ID — Truncate UUID Customer IDs for Display

Full UUID-format customer IDs (e.g. `ffebcf0-6f07-4c84-b908-f4a1dd84310f`) are too long to display cleanly in tables. A shortened display ID is created:

```dax
Short ID = "C-" & RIGHT(debitcredit[customer_id], 6)
```

This extracts the last 6 characters and prepends `"C-"`, resulting in compact identifiers like `C-84310f`. The High-Risk Transactions table uses `Short ID` instead of `customer_id`.

#### 5. Risk Flag — Dynamic Per-Row Risk Classification

Each transaction is tagged as either `"High Risk"` or `"Normal"` based on whether its amount exceeds the 95th percentile threshold of all transactions:

```dax
Risk Flag = 
IF(
    debitcredit[Amount Numeric] > PERCENTILE.INC(debitcredit[Amount Numeric], 0.95),
    "High Risk",
    "Normal"
)
```

> **Why 95th percentile?** This is a standard statistical approach for anomaly flagging — it isolates the top 5% of transactions by value as statistically unusual, without hard-coding an arbitrary dollar threshold that would become stale as transaction volumes grow.

### Calculated Columns on Supporting Tables

#### On `branch_mom_growth` — Month Display Label

```dax
Month Display = 
VAR m = VALUE(RIGHT(branch_mom_growth[txn_month], 2))
VAR y = LEFT(branch_mom_growth[txn_month], 4)
RETURN SWITCH(m,
    1,"Jan", 2,"Feb", 3,"Mar", 4,"Apr",
    5,"May", 6,"Jun", 7,"Jul", 8,"Aug",
    9,"Sep", 10,"Oct", 11,"Nov", 12,"Dec")
& " " & y
```

Converts the `YYYY-MM` string format (e.g. `2024-03`) into a human-readable label (`Mar 2024`) for chart axis display.

#### On `branch_mom_growth` — Growth Display Formatting

```dax
Growth Display = 
IF(
    ISBLANK(branch_mom_growth[mom_growth_pct]),
    "—",
    FORMAT(branch_mom_growth[mom_growth_pct], "0.00") & "%"
)
```

For the first month of each branch's history (where there is no prior month to compare against), `mom_growth_pct` is NULL. This column converts the NULL to a clean `"—"` dash in the visual, and formats all real values as `"12.34%"`.

#### On `txn_per_month` — Month Sort Order

```dax
Month Sort = VALUE(LEFT(txn_per_month[txn_month], 4)) * 100 + VALUE(RIGHT(txn_per_month[txn_month], 2))
```

Produces a numeric sort key (e.g. `202403` for March 2024) so that month labels sort correctly in chronological order on charts, not alphabetically.

```dax
Month Label = 
VAR m = VALUE(RIGHT(txn_per_month[txn_month], 2))
RETURN SWITCH(m,
    1,"Jan", 2,"Feb", 3,"Mar", 4,"Apr",
    5,"May", 6,"Jun", 7,"Jul", 8,"Aug",
    9,"Sep", 10,"Oct", 11,"Nov", 12,"Dec")
```

#### On `txn_per_week` — Week Number Label

```dax
Week Label = VALUE(RIGHT(txn_per_week[txn_week], 2))
```

Extracts the numeric week number from the `YYYY - Week WW` string format for clean axis labeling on weekly charts.

#### On `high_risk_transactions` — Formatted Date Display

```dax
Date Clean = FORMAT(high_risk_transactions[readable_date], "DD MMM YYYY")
```

Converts the raw `readable_date` field into a display-friendly format like `15 Mar 2024` for use in the high-risk transactions detail table.

---

## DAX Measures — Core KPIs

All KPI measures are written on the `debitcredit` table (via **Modeling → New Measure**). Because they use DAX `CALCULATE` and `FILTER` context, every measure automatically responds to slicer selections — filtering by date, branch, bank, or transaction type will update every KPI card instantly.

### KPI 1 — Total Credit

Sums all transaction amounts where the transaction type is `'Credit'`:

```dax
Total Credit = 
CALCULATE(
    SUM(debitcredit[Amount Numeric]),
    debitcredit[transaction_type] = "Credit"
)
```

### KPI 2 — Total Debit

Sums all transaction amounts where the transaction type is `'Debit'`:

```dax
Total Debit = 
CALCULATE(
    SUM(debitcredit[Amount Numeric]),
    debitcredit[transaction_type] = "Debit"
)
```

### KPI 3 — Net Transaction Amount

Represents the overall net flow of money — how much more was credited than debited (or vice versa):

```dax
Net Transaction Amount = 
[Total Credit] - [Total Debit]
```

A positive value indicates net inflows; a negative value indicates net outflows. This is a critical health metric for any banking portfolio.

### KPI 4 — Credit-to-Debit Ratio

A ratio expressing how many rupees (or units of currency) were credited for every rupee debited:

```dax
Credit Debit Ratio = 
DIVIDE([Total Credit], [Total Debit])
```

`DIVIDE()` is used instead of `/` to gracefully handle division-by-zero scenarios (returns BLANK instead of an error when Total Debit is zero).

A ratio > 1 means more money is flowing in than out; < 1 means more is flowing out. This gives operations teams an at-a-glance liquidity signal.

### KPI 5 — Total Transactions

Count of all rows in the `debitcredit` table (i.e. total number of transactions in the current filter context):

```dax
Total Transactions = 
COUNTROWS(debitcredit)
```

### KPI 6 — Total Amount (All Transactions)

Unconditional sum of all transaction amounts regardless of type — used for branch and bank volume comparisons:

```dax
Total Amount = 
SUM(debitcredit[Amount Numeric])
```

This measure powers the "Total Amount by Branch" and "Transaction Volume by Bank" bar charts, where both credits and debits contribute to overall branch/bank activity.

### KPI 7 — Risk Threshold (95th Percentile)

Calculates the dynamic 95th percentile cutoff for transaction amounts. Any transaction above this value is flagged as high-risk:

```dax
Risk Threshold = 
PERCENTILEINC(debitcredit[Amount Numeric], 0.95)
```

This threshold automatically recalculates as slicers are applied — meaning the risk threshold adapts to whatever subset of data is currently in view. Filtering to a specific branch, for example, recalculates the threshold against that branch's transactions only.

### KPI 8 — Suspicious Transactions Count

Counts transactions that exceed the dynamically computed 95th percentile threshold:

```dax
Suspicious Transactions = 
VAR Threshold = 
    PERCENTILE.INC(debitcredit[Amount Numeric], 0.95)
RETURN
CALCULATE(
    COUNTROWS(debitcredit),
    debitcredit[Amount Numeric] > Threshold
)
```

The threshold is computed as a `VAR` within the measure so it is evaluated in the current filter context, then used as a filter condition inside `CALCULATE`. This ensures the suspicious count always reflects the top 5% of whatever data is currently selected.

### KPI 9 — Risk Rate %

Expresses suspicious transactions as a percentage of total transactions:

```dax
Risk Rate % = 
DIVIDE([Suspicious Transactions], [Total Transactions]) * 100
```

By definition this will always approximate 5% on the full unfiltered dataset (since the threshold is set at the 95th percentile). However, when filters are applied (e.g. looking at a specific branch or date range), the percentage can shift meaningfully — a branch with 8% risk rate deserves more scrutiny than one with 3%.

---

## Risk Intelligence Layer

### Dynamic Risk Flagging Column

The `Risk Flag` calculated column (described above) enables slice-and-dice of the high-risk population in any visual. Since it is a column (not a measure), it can be used as a filter, a legend dimension, or a row-level label.

### High-Risk Transaction Logic

The risk intelligence approach in this dashboard is deliberately **data-driven rather than rule-based**:

- Instead of a hard-coded amount threshold (which would need manual updating as transaction volumes evolve), the 95th percentile is recomputed dynamically from the actual data.
- This means that as new transaction data arrives, the threshold self-adjusts to always flag the top 5% by value.
- The `CROSS JOIN DynamicThreshold` pattern used in the SQL layer was the foundation for this logic, which was then fully rebuilt in DAX for interactivity.

---

## Data Transformation & Enrichment Columns

### Date Handling

The most significant data engineering challenge in this project was the date format. Dates in the source CSV were stored as **Excel serial numbers** — plain integers representing the count of days elapsed since December 30, 1899 (Excel's epoch). Standard Power BI date parsing cannot handle this format natively.

The solution was a two-step approach:

1. `Proper Date` column converts the serial integer to a true datetime value
2. `Date Only` column then strips the time component for clean day-level aggregation

Both columns are used in the Calendar table relationship and in all time-based visuals.

### Customer ID Shortening

UUID-format customer IDs are 36 characters long and visually cluttered in table visuals. The `Short ID` column takes only the last 6 characters of the UUID and prepends `"C-"`, creating a compact 8-character display identifier. This makes the high-risk transactions table much more readable without losing the ability to trace back to the original full ID if needed.

### Display Labels for Time Series

Time-series data from the database stores months as `YYYY-MM` strings (e.g. `2024-01`). While computationally clean, these strings do not display elegantly on chart axes. The `Month Label` and `Month Display` columns use DAX `SWITCH()` to map month numbers to abbreviated names (`Jan`, `Feb`, etc.) and concatenate the year, producing labels like `Jan 2024`.

Crucially, these labels are paired with numeric sort columns (`Month Sort`) so that Power BI sorts the axis chronologically, not alphabetically (which would incorrectly place `Apr` before `Jan`).

### Month-over-Month Growth Display

The `branch_mom_growth` table contains a raw `mom_growth_pct` column that has NULL values for the first month of each branch's history. The `Growth Display` column handles this gracefully by showing `"—"` for nulls and a formatted `"0.00%"` string for real values.

---

## Dashboard Visuals & Charts

### KPI Cards

The dashboard's top row contains six KPI cards displaying:

| Card | Measure | Insight |
|---|---|---|
| **Total Credit** | `[Total Credit]` | Total money credited in current filter context |
| **Total Debit** | `[Total Debit]` | Total money debited in current filter context |
| **Net Transaction Amount** | `[Net Transaction Amount]` | Net flow of funds (positive = net inflow) |
| **Credit-to-Debit Ratio** | `[Credit Debit Ratio]` | Liquidity health signal |
| **Total Transactions** | `[Total Transactions]` | Transaction count |
| **Risk Rate %** | `[Risk Rate %]` | Proportion of high-risk transactions |

All cards update instantly when any slicer is changed.

### Transaction Volume Over Time

Three time-granularity views are available for transaction volume:

- **Daily** — plotted using `Date Only` on the X-axis and `Total Transactions` or `Total Amount` on the Y-axis
- **Weekly** — plotted using `Week Label` (sorted by `Week Label` numerically)
- **Monthly** — plotted using `Month Label` (sorted by `Month Sort` numerically)

This multi-granularity design allows analysts to zoom into specific weeks for anomaly investigation or zoom out to monthly trends for strategic reporting.

### Total Amount by Branch (Bar Chart)

- **X-axis:** `[Total Amount]` (sum of all credits AND debits)
- **Y-axis:** `branch` dimension from `debitcredit`
- Sorted descending by total amount

This chart answers: *"Which branches are driving the highest overall transaction volume?"*

### Transaction Volume by Bank

- **X-axis:** `[Total Amount]`
- **Y-axis:** `bank_name`
- Sorted descending

Reveals which banking partners or institutions are most active in the dataset, useful for network analysis and partnership decisions.

### Transaction Method Distribution

- Visual type: Donut or Pie chart
- **Legend:** `transaction_method`
- **Values:** `COUNTROWS(debitcredit)` (or `[Total Transactions]`)

Breaks down how customers are transacting — e.g. what percentage use ATM vs UPI vs NEFT vs Online Banking. This drives decisions around which payment channels to invest in.

### Branch Month-over-Month Growth

- Visual type: Line chart or Matrix
- Uses the `branch_mom_growth` data, displayed with `Month Display` on the axis and `mom_growth_pct` as the value
- `Growth Display` column provides the formatted percentage label for tooltips and data labels

Reveals which branches are accelerating or decelerating in transaction volume over time.

### High-Risk Transactions Table

A detail-level table showing every transaction flagged as high-risk, with columns:

| Column Shown | Source |
|---|---|
| `Short ID` | Calculated column on `debitcredit` |
| `account_number` | Direct from `debitcredit` |
| `Date Clean` | Calculated column on `high_risk_transactions` |
| `Amount Numeric` | Calculated column on `debitcredit` |
| `Risk Flag` | Calculated column on `debitcredit` |

This table allows compliance teams to drill into specific suspicious transactions for review.

---

## Making the Dashboard Fully Dynamic

The most important architectural decision in this project was **rebuilding all KPIs as DAX measures on the `debitcredit` table** rather than referencing static pre-aggregated tables from SQL.

**Why this matters:** If KPI cards reference SQL-side aggregated tables (like a `total_credit` table with a single row), those values are fixed at import time and **do not respond to Power BI slicers**. Slicing by branch or date would change every other visual but the KPI cards would remain frozen at their full-dataset values — a deeply misleading user experience.

By rewriting all KPIs as DAX measures with `CALCULATE()`, they evaluate within the **current filter context** established by all active slicers at any moment. This means:

- Selecting "Mumbai Branch" from the Branch slicer → all KPI cards immediately reflect Mumbai-only numbers
- Selecting a date range → all cards, charts, and tables show only that period's data
- Combining multiple slicer selections → the intersection is evaluated correctly

This design pattern — **DAX measures as the KPI engine, slicers as the runtime filter, and `debitcredit` as the single fact table** — is what transforms a static report into a truly interactive analytics tool.

---


## Error Logs & How They Were Solved

### 1. Excel Serial Date Numbers

**Problem:** `transaction_date` is stored as a plain integer (Excel serial number), not a recognizable date string. Power BI cannot parse this automatically.

**Solution:** Created `Proper Date = DATE(1899, 12, 30) + VALUE(debitcredit[transaction_date])` as a calculated column. The offset `1899-12-30` is Excel's epoch — adding the integer to this base date produces the correct calendar date.

### 2. Proper Date Contains Time Component

**Problem:** `Proper Date` sometimes carries a time component, causing grouping issues when plotting daily transaction counts (the same calendar day could appear as multiple "dates").

**Solution:** Created `Date Only` column using `DATE(YEAR(...), MONTH(...), DAY(...))` to extract just the date portion, dropping any time component.

### 3. Amount Stored as TEXT

**Problem:** All columns in `debitcredit` were loaded as `TEXT` in MySQL. DAX `SUM()` and `DIVIDE()` cannot operate on text values.

**Solution:** Created `Amount Numeric = VALUE(debitcredit[amount])` calculated column. All financial measures reference `Amount Numeric`.

### 4. KPI Cards Not Responding to Slicers

**Problem:** Initial KPI cards were built from SQL-side aggregated tables (single-row tables like `total_credit`). These are static imports and ignore Power BI filter context.

**Solution:** Deleted all pre-aggregated table references in KPI visuals and rewrote every measure as DAX `CALCULATE()` measures directly on `debitcredit`. These evaluate dynamically within slicer context.

### 5. Month Labels Sorting Alphabetically

**Problem:** `txn_month` strings like `"2024-01"` and `"2024-02"` display correctly but month abbreviation labels like `"Jan"`, `"Feb"` sort alphabetically (`Apr`, `Aug`, `Dec`...) instead of chronologically.

**Solution:** Created `Month Sort` as a numeric key (`YYYYMM` integer). Set the `Month Label` column's **Sort by Column** property to `Month Sort` in Power BI's column properties. This forces chronological ordering in all visuals.

### 6. UUID Customer IDs Too Long for Tables

**Problem:** Full UUIDs (36 characters) overflow table column widths and are visually unreadable.

**Solution:** Created `Short ID = "C-" & RIGHT(debitcredit[customer_id], 6)` to display a compact 8-character identifier in the high-risk transactions table.

### 7. NULL Growth Values for First Month

**Problem:** The first month of data for each branch has no prior month to compare against, resulting in NULL `mom_growth_pct` values that display as blank cells in visuals.

**Solution:** Created `Growth Display` column that maps NULL to `"—"` using `IF(ISBLANK(...), "—", FORMAT(...) & "%")`.

### 8. ODBC Driver Not Detected by Power BI

**Problem:** After installing the MySQL ODBC driver, Power BI still could not detect it.

**Solution:** Must fully close Power BI Desktop and restart the PC after driver installation. The Windows driver registry is read at application startup; a running Power BI instance does not pick up newly registered drivers.

---

*Built with MySQL 8.0 and Microsoft Power BI Desktop.*