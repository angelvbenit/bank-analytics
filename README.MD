# ADVANCED EXCEL
# Banking Dashboard: Power Query, Data Model & DAX KPIs

![Banking Analytics Animation](https://github.com/angelvbenit/bank-analytics/raw/main/advanced-excel/banking.gif)

First dashboard in the series. Built end-to-end from a raw 6-sheet banking dataset to a fully interactive, slicer-driven KPI dashboard backed by a star-schema data model and 23 live DAX measures.

---

## 1. Project Summary

| | |
|---|---|
| **Source file** | `dataset1.xlsx` (untouched) |
| **Working file** | `BankingDashboard.xlsx` |
| **Sheets imported** | 6 — Dim Client, Dim Branch, Dim Product, Fact Loan, Fact Repayment, Final Fact |
| **Row counts** | Dim Client: 1,000 · Dim Branch: 180 · Dim Product: 11 · Fact Loan: 2,000 · Fact Repayment: 2,000 · Final Fact: 2,000 (pre-joined, reference only) |
| **Date range** | Disbursement dates span 2015–2023 |
| **Loan statuses** | Active, Fully Paid, Paid Off, Default |
| **Data model** | Star schema, 5 relationships, dedicated Calendar table built in Power Query |
| **KPI measures** | 17 core + 6 additional = 23 total |
| **Dashboard surface** | KPI cards, branch bar chart, product volume/profitability combo chart, branch performance donut, Year/Purpose Category slicers |

---

## 2. Why This Structure:


- **Source file is never opened directly, only imported via Get Data.** Power Query self-references corrupt the model on refresh if you import into the same file you're building in. 
- **"Transform Data" not "Load."** Loading directly skips every cleaning step and pushes raw, untyped data straight into the model.
- **Final Fact (the pre-joined denormalized table) is loaded but never used in measures.** It exists as a backup/reference table only. Building measures off Fact Loan + Fact Repayment instead avoids double-counting that a pre-joined flat table would introduce.
- **Measures live in fact tables, not dimension tables.** Power Pivot convention; keeps the Calculation Area logically grouped with the transactional data the measures aggregate.
- **A dedicated Calendar table was built in Power Query, referencing Fact Loan directly — not with the DAX `CALENDAR()` function.** Time intelligence functions require a proper marked Date Table, and a calculated DAX table with no explicit bounds can silently pick up dates from an unrelated table elsewhere in the model (see §3.3 for the actual bug this caused and how it was fixed).

---

## 3. Data Model

### 3.1 Tables & Cleaning Notes

| Table | Role | Join Key | Notable Cleaning Applied |
|---|---|---|---|
| **Dim Client** | Dimension | Client ID (Whole Number) | Renamed `Client id`→`Client ID`, `Age _T`→`Age_T`, `Dateof Birth`→`Date of Birth`. Removed duplicate/null Client IDs. |
| **Dim Branch** | Dimension | BranchID (Text) | BranchID format verified (e.g. `PATIALA-100186`) via Column from Examples. Blank rows removed. |
| **Dim Product** | Dimension | Product Id (Text) | Int Rate kept as raw decimal (e.g. `0.1065`) — **not** multiplied; DAX measure formats it as % later. Trimmed trailing whitespace from Purpose Category (fixed `"Fectory "` → `"Factory"`-style entries). |
| **Fact Loan** | Fact (center) | Account ID | Disbursement Date set to Date type (critical for time intelligence). `Client id` renamed to `Client ID` to match Dim Client exactly. |
| **Fact Repayment** | Fact | Account ID (Text) | Flag columns (`Is Delinquent Loan`, `Is Default Loan`, `Repayment Behavior`) kept as Text, not Boolean — values are stored as Y/N strings. |
| **Final Fact** | Reference only | — | Duplicate join columns removed (`Branch Name_y`, `State Abbr.1`, `Center Id_y`); `_x` versions kept and renamed. Not used in any measure. |

### 3.2 Relationships (Star Schema)

| ID | From (Many) | To (One) | Key | Active |
|---|---|---|---|---|
| R1 | Fact Loan[Client ID] | Dim Client[Client ID] | Client ID | Yes |
| R2 | Fact Loan[BranchID] | Dim Branch[BranchID] | BranchID | Yes |
| R3 | Fact Loan[Product Id] | Dim Product[Product Id] | Product Id | Yes |
| R4 | Fact Repayment[Account ID] | Fact Loan[Account ID] | Account ID | Yes |
| R5 | Calendar[Date] | Fact Loan[Disbursement Date] | Date | Yes |

**Shape:** Fact Loan sits at the centre, connecting outward to Dim Client, Dim Branch, Dim Product, and Calendar, with Fact Repayment feeding into Fact Loan via Account ID.

### 3.3 Calendar Table (Power Query — referenced, not DAX-generated)

The Calendar table was built in **Power Query**, not with the DAX `CALENDAR()` function. A DAX-generated calendar (or "Mark as Date Table" applied without a clean source) pulled in dates from 1960 — Power Pivot was defaulting to the earliest date column it could find across the model, which turned out to be `Dim Client[Date of Birth]`, not `Fact Loan[Disbursement Date]`. The fix was to build the Calendar as a **query referencing Fact Loan directly**, so it's structurally impossible for it to contain anything outside the loan date range.

**Build steps:**

| Step | Action |
|---|---|
| 1 | Power Query Editor → right-click `Fact Loan` → **Reference** (creates a new linked query) |
| 2 | Rename the new query to `Calendar` |
| 3 | Keep only `Disbursement Date` → Remove Other Columns |
| 4 | Right-click `Disbursement Date` → **Remove Duplicates** (unique list of every date a loan was issued) |
| 5 | Rename column to `Date` |
| 6 | Add Column → Date → **Year**, **Name of Month**, **Quarter of Year** |
| 7 | Set `Date` column type to Date |
| 8 | Close & Load To… → Add this data to the Data Model |

**Connect and finalize in Power Pivot:**

| Step | Action |
|---|---|
| 9 | Diagram View → drag `Calendar[Date]` → `Fact Loan[Disbursement Date]`, set Active |
| 10 | Select the `Calendar` tab → Design ribbon → **Mark as Date Table** → `[Date]` column |

Because the query is a direct reference to Fact Loan, the Calendar table is guaranteed to span exactly 2015–2023 — it can never inherit an out-of-range date from another table in the model.

---

## 4. KPI Measures (23 Total)

### 4.1 Client KPIs

```dax
Total Clients :=
COUNTROWS('Dim Client')

Active Clients :=
CALCULATE(
    DISTINCTCOUNT('Fact Loan'[Client ID]),
    'Fact Loan'[Loan Status] = "Active"
)

New Clients :=
CALCULATE(
    DISTINCTCOUNT('Fact Loan'[Client ID]),
    FILTER(
        'Fact Loan',
        CALCULATE(
            MIN('Fact Loan'[Disbursement Date]),
            ALLEXCEPT('Fact Loan', 'Fact Loan'[Client ID])
        ) >= MIN('Calendar'[Date])
        &&
        CALCULATE(
            MIN('Fact Loan'[Disbursement Date]),
            ALLEXCEPT('Fact Loan', 'Fact Loan'[Client ID])
        ) <= MAX('Calendar'[Date])
    )
)

Client Retention Rate :=
VAR CurrClients = DISTINCTCOUNT('Fact Loan'[Client ID])
VAR PrevClients =
    CALCULATE(
        DISTINCTCOUNT('Fact Loan'[Client ID]),
        DATEADD('Calendar'[Date], -1, YEAR)
    )
RETURN
    DIVIDE(CurrClients, PrevClients, 0)
```

### 4.2 Loan Volume & Size KPIs

```dax
Total Loan Amount :=
SUM('Fact Loan'[Loan Amount])

Total Funded Amount :=
SUM('Fact Loan'[Funded Amount])

Avg Loan Size :=
AVERAGE('Fact Loan'[Loan Amount])

Loan Growth % :=
VAR CurrAmt = SUM('Fact Loan'[Loan Amount])
VAR PrevAmt =
    CALCULATE(
        SUM('Fact Loan'[Loan Amount]),
        DATEADD('Calendar'[Date], -1, YEAR)
    )
RETURN
    DIVIDE(CurrAmt - PrevAmt, PrevAmt, 0)
```

### 4.3 Repayment & Income KPIs

```dax
Total Repayments :=
SUM('Fact Repayment'[Total Pymnt])

Principal Recovery Rate :=
DIVIDE(
    SUM('Fact Repayment'[Total Rec Prncp]),
    SUM('Fact Loan'[Loan Amount]),
    0
)

Interest Income :=
SUM('Fact Repayment'[Total Rrec int])
```

### 4.4 Risk & Quality KPIs

```dax
Default Rate :=
DIVIDE(
    CALCULATE(COUNTROWS('Fact Repayment'), 'Fact Repayment'[Is Default Loan] = "Y"),
    COUNTROWS('Fact Repayment'),
    0
)

Delinquency Rate :=
DIVIDE(
    CALCULATE(COUNTROWS('Fact Repayment'), 'Fact Repayment'[Is Delinquent Loan] = "Y"),
    COUNTROWS('Fact Repayment'),
    0
)

On-Time Repayment % :=
DIVIDE(
    CALCULATE(COUNTROWS('Fact Repayment'), 'Fact Repayment'[Repayment Behavior] = "On-Time"),
    COUNTROWS('Fact Repayment'),
    0
)
```

### 4.5 Branch & Product KPIs

```dax
Loan by Branch :=
CALCULATE(
    SUM('Fact Loan'[Loan Amount]),
    ALLEXCEPT('Dim Branch', 'Dim Branch'[Branch Name])
)
-- Use in PivotTable with Dim Branch[Branch Name] as Row

Product Loan Volume :=
CALCULATE(
    SUM('Fact Loan'[Loan Amount]),
    ALLEXCEPT('Dim Product', 'Dim Product'[Purpose Category])
)
-- Use in PivotTable with Dim Product[Purpose Category] as Row

Product Profitability :=
CALCULATE(
    SUM('Fact Repayment'[Total Rrec int]),
    ALLEXCEPT('Dim Product', 'Dim Product'[Purpose Category])
)
-- Use in PivotTable with Dim Product[Purpose Category] as Row
```

### 4.6 Additional Recommended KPIs (Phase 7)

```dax
Avg Credit Score :=
AVERAGE('Dim Client'[Credit Score])

Total Late Fees :=
SUM('Fact Repayment'[Total Rec Late Fee])

Loan to Funded Ratio :=
DIVIDE(
    SUM('Fact Loan'[Loan Amount]),
    SUM('Fact Loan'[Funded Amount]),
    0
)

Recoveries :=
SUM('Fact Repayment'[Total Pymnt])
    - SUM('Fact Repayment'[Total Rec Prncp])
    - SUM('Fact Repayment'[Total Rrec int])
-- Note: cross-check against Recoveries column in Final Fact if added to Fact Repayment

Active Book Value :=
CALCULATE(
    SUM('Fact Loan'[Loan Amount]),
    'Fact Loan'[Loan Status] = "Active"
)

Avg Delinquencies :=
AVERAGE('Fact Repayment'[Delinq 2 Yrs])
```

### 4.7 Measure Formatting

| Measures | Format | Format String |
|---|---|---|
| Total Clients, Active Clients, New Clients | Whole Number | `#,##0` |
| Client Retention Rate, Default Rate, Delinquency Rate, On-Time Repayment %, Loan Growth %, Principal Recovery Rate | Percentage | `0.00%` |
| Total Loan Amount, Total Funded Amount, Total Repayments, Interest Income, Avg Loan Size, Loan by Branch, Product Loan Volume, Product Profitability | Currency | `₹#,##0` |

### 4.8 KPI Traffic Lights (Optional)

Applied to **Default Rate**: target = 0.05 (5% threshold) · Good (green) < 0.03 · OK (yellow) 0.03–0.05 · Bad (red) > 0.05.
Applied to **On-Time Repayment %**: target = 0.90 (90%).

---

## 5. Dashboard Layout

| Element | Built As |
|---|---|
| KPI cards (top row) | One small PivotTable per KPI, tabular form, no subtotals, bordered + filled, bold number with label above |
| Branch Loan Distribution | PivotTable (Rows: Dim Branch[Branch Name], Values: Total Loan Amount) → Clustered Bar, sorted descending |
| Branch Performance Category | PivotTable (Rows: Dim Branch[Branch Performance Category], Values: Total Loan Amount) → Doughnut chart |
| Which Loan Products Are Most Profitable? | PivotTable (Rows: Dim Product[Purpose Category], Values: Product Loan Volume + Product Profitability) → Combo chart (Bar + Line) |
| Loan Growth Trend | PivotTable (Rows: Calendar[Year], Values: Total Loan Amount) → Line chart, Loan Growth % on secondary axis |
| Slicers | Year (Calendar[Year]), Purpose Category (Dim Product[Purpose Category]) — both connected via Report Connections to every PivotTable/PivotChart on the sheet |

**Background:** Light gray (`#F1F5F9`) canvas, gridlines removed, top row frozen for the title.

### Result (as built)

| KPI | Value |
|---|---|
| Total Clients | 1,000 |
| Active Clients | 324 |
| New Clients | 870 |
| Client Retention Rate | 104.07% |
| Total Loan Amount Disbursed | ₹52.36 M |
| Total Funded Amount | ₹52.36 M |
| Average Loan Size | ₹26.18 k |
| Loan Growth % | 13.72% |
| Total Repayments Collected | ₹53.86 M |
| Principal Recovery Rate | 99.05% |
| Interest Income | ₹5.06 M |
| Default Rate | 5.00% |
| Delinquency Rate | 10.35% |
| On-Time Repayment % | 71.05% |

Top branches by loan volume: Dhuri (₹4.79 M), Muktsar (₹4.41 M), Behror (₹4.22 M), Mathura (₹4.11 M), Durgapur (₹3.63 M). Branch performance split: High 22%, Medium 35%, Low (remainder). Services and Trade dominate product loan volume; Services shows the steepest profitability spike on the combo chart.

---

## 6. QA / Validation Checklist

Run this before treating any KPI as trustworthy.

| Check | Expected | Manual Verification |
|---|---|---|
| Total Clients | = 1,000 | `=COUNTA(DimClient[Client ID])` in a plain cell |
| Total Loans | = 2,000 | `=COUNTA(FactLoan[Account ID])` in a plain cell |
| Default Rate | Between 0–100%, not blank | Manually count `Is Default Loan = Y` in Fact Repayment |
| Active Clients ≤ Total Clients | Must hold | Compare KPI cards directly |
| Loan Growth % for 2015 | Blank or 0 (no prior year) | Filter Year slicer to 2015, check for errors |
| Principal Recovery Rate | ≤ 1 (≤100%) | Very high values flag a data-type issue upstream |
| All 6 tables show "Connection only" + in Data Model | — | Data tab → Queries & Connections pane |
| Refresh All completes with no red error icons | — | `Ctrl+Alt+F5` |

**Auto-refresh on open:** Data → Connections → Properties → tick "Refresh data when opening the file."

---

## 7. Error Log (Rule-Linked)

Following the same format used in the SQL practice files — every fix is tied back to the rule that explains *why* it broke.

| Symptom | Root Cause | Rule It Violates | Fix |
|---|---|---|---|
| KPI shows blank/(empty) | Table not loaded to Data Model | Every query needs "Add this data to the Data Model" ticked individually — it is not inherited or bulk-applied | Power Query → Close & Load To → re-tick "Add to Data Model" |
| DAX error on `DATEADD` | Calendar table not marked as Date Table | Time intelligence functions require a table explicitly flagged as the model's date dimension, not just a column typed as Date | Power Pivot → Calendar table → Design → Mark as Date Table |
| Slicers don't filter other PivotTables | Report Connections not configured | A slicer only filters the PivotTables it's explicitly wired to — connection is per-slicer, not global | Right-click slicer → Report Connections → tick all PivotTables |
| Default Rate = 100% | `Is Default Loan` has wrong data type | Y/N flag columns must stay Text; coercing to another type breaks the string comparison in the measure | Power Query → set column to Text, confirm values are Y/N |
| New Clients count wrong/inflated | MIN disbursement date logic not filtering correctly | The "first transaction per client" pattern requires `ALLEXCEPT` scoped to Client ID specifically, not the whole table | Add Calendar slicer, test on a single year, compare to manual `COUNTIF` |
| Relationship inactive/broken | Join key type mismatch (Text vs Number) | Relationships require identical data types on both sides of the join — Power Pivot will not auto-coerce | Power Query → match both sides to same type (e.g. both Text for BranchID) |
| Power Pivot tab missing | COM Add-in disabled, or Excel version too old | Power Pivot is an opt-in COM Add-in, not enabled by default, and requires Excel 2016+ | File → Options → Add-ins → COM Add-ins → tick Power Pivot |
| Year slicer shows 1960 onward instead of 2015–2023 | DAX-generated Calendar / "Mark as Date Table" pulled its range from the earliest date column anywhere in the model — `Dim Client[Date of Birth]` — instead of `Fact Loan[Disbursement Date]` | A Date Table's range is only as trustworthy as its source; a calculated table with no explicit lower bound can silently inherit dates from an unrelated table in the model | Rebuilt Calendar in Power Query as a direct **Reference** of Fact Loan (dedup on Disbursement Date only), so it is structurally limited to the loan date range — see §3.3 |

---

## 8. Build Phases (Reference Index)

1. **Phase 0** — Pre-import setup: fresh workbook, enable Power Pivot COM Add-in
2. **Phase 1** — Import all 6 tables via Power Query (Transform Data, not Load), clean and type each
3. **Phase 2** — Build star-schema relationships + Calendar table (Power Query reference method)
4. **Phase 3** — Write all 17 core KPI measures in Power Pivot
5. **Phase 4** — Format measures, add KPI traffic-light indicators
6. **Phase 5** — Build dashboard layout: KPI cards, charts, slicers
7. **Phase 6** — Refresh, validate, run QA checklist
8. **Phase 7** — 6 additional recommended KPIs (credit score, late fees, recoveries, etc.)

---

## 9. Tech Stack

`Power Query` · `Power Pivot (Data Model)` · `DAX` · `PivotTables / PivotCharts` · `Slicers` · Excel 2016+

---
# Bank Debit and Credit Dashboard: Power Query, SUMIFS Engine & Pivot Engine

![Bank Debit Credit Animation](https://github.com/angelvbenit/bank-analytics/raw/main/advanced-excel/bank-debit-credit.gif)

Second dashboard in the series. Unlike the first Banking Dashboard (built on Power Pivot + DAX), this one is built on a lighter-weight stack: Power Query for cleaning, plain `SUMIFS`/`COUNTIF` formulas for headline KPIs, and a separate hidden "Pivot Engine" sheet for categorical breakdowns and charts. It also introduces a statistically-driven fraud/anomaly KPI using `PERCENTILE.INC`.

---

## 1. Project Summary

| | |
|---|---|
| **Source file** | `Debit and Credit banking_data.xlsx - Sheet1.csv` |
| **Cleaned query name** | `BankData` |
| **Total transactions** | 10,000 |
| **Sheets** | Dashboard (front-end), Pivot Engine (hidden, back-end) |
| **KPI count** | 12 |
| **Architecture** | Data Model / Power Pivot only for 4 KPIs |
| **Dashboard surface** | KPI cards, suspicious-activity banner, branch bar chart, transaction method donut, time-series line chart, bank volume bar chart, branch growth multi-line chart, Branch slicer |

---

## 2. Why This Structure (Design Rationale)



- **Structured table references (`BankData[Amount]`, `BankData[Transaction Type]`) instead of cell ranges.** This is the reason the query was renamed from the messy source filename to `BankData` immediately after import — clean table names are what make formulas like `=SUMIFS(BankData[Amount], BankData[Transaction Type], "Credit")` readable and resilient to row insertions.
- **A hidden "Pivot Engine" sheet separates calculation from presentation.** The 5 categorical KPIs (branch, bank, method, time trend, growth) are built as PivotTables on their own back-end sheet, then the resulting PivotCharts are cut and pasted onto the Dashboard sheet. This keeps the front-end visually clean while the underlying PivotTables stay editable on their own tab.
- **The 95th-percentile risk threshold is calculated once, then referenced everywhere.** Rather than hardcoding a dollar threshold for "suspicious," the threshold lives in one cell (`Dashboard!$J$2`) and every transaction is flagged against it with a single `IF` formula. This makes the entire risk model self-adjusting as the dataset changes — see §5.

---

## 3. Phase 1 — Import & Cleaning (Power Query)

| Step | Action |
|---|---|
| 1 | Get Data → From File → From Text/CSV → select `Debit and Credit banking_data.xlsx - Sheet1.csv` |
| 2 | Click **Transform Data** (not Load) to open Power Query Editor |
| 3 | Set `Amount` column → Decimal Number / Currency |
| 4 | Set `Transaction Type` column → Text |
| 5 | Set `Transaction Date` column → Date |
| 6 | Rename the query from the long source filename to **`BankData`** |
| 7 | Close & Load → dumps the cleaned data into a new sheet as a structured (green) Excel Table |

**Why renaming the query matters:** every downstream formula in this dashboard references `BankData[ColumnName]`. Skipping the rename means every formula has to reference an unreadable auto-generated query name instead.

---

## 4. Phase 2 — Headline KPI Formulas (Dashboard Sheet)

All four formulas below are placed directly on the **Dashboard** sheet and reference the `BankData` table — no PivotTable required.

| KPI | Cell | Formula | Format |
|---|---|---|---|
| **1. Total Credit Amount** | B2 | `=SUMIFS(BankData[Amount], BankData[Transaction Type], "Credit")` | `₹ #,##0.0,,"M"` |
| **2. Total Debit Amount** | B3 | `=SUMIFS(BankData[Amount], BankData[Transaction Type], "Debit")` | `₹ #,##0.0,,"M"` |
| **3. Credit to Debit Ratio** | — | `=B2 / B3` | `0.00x` |
| **4. Net Transaction Amount** | — | `=B2 - B3` | `₹ #,##0.0,"K"` |

> **Note on Net Transaction Amount:** if debits exceed credits, this naturally returns negative — that's correct behavior, representing net negative cash flow for the period, not an error to fix.

---

## 5. The 95th Percentile High-Risk Threshold (KPI 11 + 12)

### 5.1 Business Purpose

In banking, transactions need a way to be flagged "High-Risk" for manual review, a real-world requirement for anti-money-laundering and fraud detection workflows. A hardcoded dollar threshold (e.g. "anything over ₹5,000 is suspicious") breaks in two ways:

- **False positives** — a threshold tuned for a retail branch will flag thousands of normal transactions at a corporate branch where ₹5,000 is routine.
- **False negatives** — as the bank grows or inflation shifts typical transaction size, a fixed threshold goes stale and stops catching real outliers.

The fix is to let the data define "normal" instead of guessing a number: the 95th percentile asks the dataset "what is the cutoff above which only the top 5% most extreme transactions sit?" ; and recalculates automatically as the data changes.

### 5.2 The Formula

```excel
J1: High Risk Threshold (95th Percentile)
J2: =PERCENTILE.INC(BankData[Amount], 0.95)
```

**What Excel does under the hood:**
1. **Sort** — every transaction amount in `BankData` (all 10,000 rows) is sorted from smallest to largest.
2. **Cutoff** — the sorted list is split into the bottom 95% (normal, everyday transactions) and the top 5% (extreme outliers).
3. **Value** — Excel returns the exact amount sitting on the border between those two groups. That amount becomes the live threshold in `J2`.

### 5.3 Applying the Flag (Step 1)

Back on the `BankData` table, a new column is added directly to the right of the last existing column:

```excel
Header: High Risk Flag
Formula: =IF([@Amount] > Dashboard!$J$2, "High Risk", "Normal")
```

This auto-fills down the entire structured table and tags only the top 5% of transactions — every row references the single live threshold cell, so the flag updates automatically if the underlying data changes.

### 5.4 Pulling the Flag onto the Dashboard (Step 2)

| KPI | Cell | Formula | Insight |
|---|---|---|---|
| **12. Suspicious Transaction Frequency** | B5 | `=COUNTIF(BankData[High Risk Flag], "High Risk")` | Exact count of anomalies to investigate |
| **5. Account Activity Ratio** | B6 | `=COUNTA(BankData[Account Number]) / AVERAGE(BankData[Balance])` | Dividing total transactions by *average* portfolio balance (not summed balance) gives a mathematically accurate activity-to-liquidity ratio |

### 5.5 Why This Is the Right Approach

The dashboard is "living" software: if the bank lands a major client whose transactions run far larger than the current average, the 95th-percentile threshold rises automatically to match — a hardcoded ₹5,000 rule would have broken the moment that client showed up. It is a self-adjusting, mathematically sound risk model, which is exactly why this formula resulted in flagging **5,000 transactions out of 10,000 total** — precisely the top 5%, as designed.

---

## 6. Phase 3 — The Pivot Engine (KPIs 6–10)

The 5 remaining categorical KPIs are built as PivotTables on a dedicated, hidden **Pivot Engine** sheet — kept separate from the Dashboard to avoid cluttering the front-end with calculation tables.

| KPI | Rows | Values | Notes |
|---|---|---|---|
| **7. Total Transaction Amount by Branch** | Branch | Sum of Amount | Formatted as Currency |
| **8. Transaction Volume by Bank** | Bank Name | Sum of Amount | Copied from KPI 7 PivotTable, Rows swapped |
| **9. Transaction Method Distribution** | Transaction Method | Count of Account Number | Right-click → Show Values As → % of Grand Total |
| **6. Transactions per Day/Week/Month** | Transaction Date | Count of Account Number | Right-click any date → Group → Months and Days |
| **10. Branch Transaction Growth %** | Rows: Transaction Date (grouped to Months) · Columns: Branch · Values: Sum of Amount | Show Values As → % Difference From → Base Field: Transaction Date (Months), Base Item: (Previous) |

### 6.1 KPI 10 Build Notes (Rebuilt From Scratch)

KPI 10 required a full rebuild after the initial attempt broke:

1. Deleted the broken PivotTable entirely, leaving at least 15 blank rows × 10 blank columns of clear space.
2. Copied a working PivotTable (KPI 9) into the cleared space as a fresh starting point.
3. Cleared all fields from the new PivotTable's field wells.
4. Re-added fields in this exact order: **Rows** → Transaction Date (grouped to Months, so time sits on the X-axis) · **Columns** → Branch (so each branch renders as its own line) · **Values** → Amount (defaults to Sum of Amount).
5. Converted raw dollar values to growth percentages via Show Values As → % Difference From → Previous Month.

### 6.2 Data Quality Note — December 2024 Exclusion

KPI 6's pivot table revealed that only **December 1st** had any recorded transactions for December (305 transactions, no other December dates present) — a partial-month data artifact, not a real trend. The fix: in the PivotTable date filter, December was unchecked using `"<01-01-2024"` and `">02-12-2024"` as bounds, and the following note was added directly to the chart:

> *"Note: December 2024 excluded from trend analysis due to partial month data (Dec 1 only ; 300 records)."*

This note is visible on the live dashboard (Transactions Over Time panel), a clear example of flagging a data limitation directly on the visual rather than letting it silently distort the trend line.

---

## 7. Phase 4 — Visualization (Pivot Engine → Dashboard)

| KPI | Chart Type | Build Method |
|---|---|---|
| KPI 7 (Branch Amount) | Bar Chart | PivotTable Analyze → PivotChart → Bar → cut → paste onto Dashboard |
| KPI 8 (Bank Volume) | Bar/Column Chart | Same cut-and-paste method |
| KPI 9 (Transaction Method) | Pie/Donut Chart | Same cut-and-paste method |
| KPI 6 (Transactions Over Time) | Line Chart | Same cut-and-paste method; December note added |
| KPI 10 (Branch Growth %) | Line Chart | Same cut-and-paste method; multi-line, one per branch |

All PivotCharts are built on the Pivot Engine sheet, then cut (`Ctrl+X`) and pasted (`Ctrl+V`) onto the Dashboard sheet — keeping the calculation layer and the presentation layer on separate tabs while the charts themselves remain live and refreshable.

---

## 8. Formatting Reference

| Field | Format String |
|---|---|
| Total Credit Amount / Total Debit Amount | `₹ #,##0.0,,"M"` |
| Net Transaction Amount | `₹ #,##0.0,"K"` |
| Credit to Debit Ratio | `0.00x` |
| Suspicious Transaction Frequency | Whole Number |
| Account Activity Ratio | Number / `0.0x` |

---

## 9. Dashboard Layout (As Built)

| Element | Source |
|---|---|
| Total Transactions banner | Count of all rows in BankData |
| KPI card row 1 | Total Credit Amount, Total Debit Amount, Net Transaction Amount, Credit to Debit Ratio, Total Debit Transactions, Total Credit Transactions, Total Bank Transfer Transactions |
| Risk banner | Suspicious Transaction Frequency (KPI 12), Account Activity Ratio (KPI 5) |
| Total Transaction Amount by Branch | KPI 7 — horizontal bar |
| Transaction Method Distribution | KPI 9 — donut |
| Transactions Over Time | KPI 6 — line, with December exclusion note |
| Transaction Volume by Bank | KPI 8 — vertical bar |
| Branch Transaction Growth | KPI 10 — multi-line, % difference from previous month |
| Branch slicer | Connected across relevant PivotTables/charts |

### Result (as built)

| KPI | Value |
|---|---|
| Total Transactions | 10,000 |
| Total Credit Amount | ₹127.6 M |
| Total Debit Amount | ₹127.3 M |
| Net Transaction Amount | ₹318.1 K |
| Credit to Debit Ratio | 1.00x |
| Total Debit Transactions | 33,352 |
| Total Credit Transactions | 33,310 |
| Total Bank Transfer Transactions | 33,338 |
| Suspicious Transaction Frequency | 5,000 |
| Account Activity Ratio | 19.0x |

Branch ranking by transaction amount: City Center (₹42,911K), Main (₹42,839K), East (₹42,697K), Downtown (₹42,587K), Suburban (₹42,176K), North (₹41,677K) — a notably tight spread across all six branches. Transaction method split is near-even across Bank Transfer (33.35%), Credit Card (33.34%), and Debit Card (33.31%). Transaction volume by bank ranges from ₹43,034K (Kotak Mahindra) down to ₹41,666K (HDFC).

---

## 10. Error Log (Rule-Linked)

| Symptom | Root Cause | Rule It Violates | Fix |
|---|---|---|---|
| Formulas reference an unreadable query name | Query not renamed after import | Power Query keeps the raw source filename until explicitly renamed — formulas inherit whatever the query is called at the time they're written | Rename query to `BankData` immediately after Transform Data, before writing any formula |
| KPI 10 pivot table broken/unusable | Fields added in the wrong order or left over from a copied table | A growth-over-time-by-category pivot only resolves correctly with Rows = time, Columns = category, Values = metric, in that specific order — leftover fields from a copy-paste corrupt the layout | Delete the broken table entirely, copy a clean working PivotTable into blank space, clear all fields, re-add in the correct Rows → Columns → Values order |
| December trend line looks artificially low/spiky | Only Dec 1 has transaction records for the month | A single day of data graphed alongside full months will always read as an anomaly, not a real trend — this is a data-coverage gap, not a business signal | Exclude December from the date filter (`<01-01-2024`, `>02-12-2024`), document the exclusion directly on the chart |
| High Risk Flag returns the same threshold for every row, or doesn't update | Formula references a relative cell instead of an absolute one | Without `$` locking on `Dashboard!$J$2`, the threshold reference shifts as the formula fills down the table, breaking the flag for every row but the first | Use `Dashboard!$J$2` (absolute reference) in the `IF` formula so every row checks against the same fixed threshold cell |
| Account Activity Ratio looks abnormally large or small | Balance summed instead of averaged | Summing `Balance` across 10,000 transaction rows massively inflates the denominator, since balance is a snapshot value repeated per transaction, not a per-transaction quantity to be totaled | Use `AVERAGE(BankData[Balance])`, not `SUM`, as the denominator |

---

## 11. Build Phases (Reference Index)

1. **Phase 1** — Import via Power Query (Transform Data, not Load), set types, rename query to `BankData`
2. **Phase 2** — Build first 4 KPIs directly on the Dashboard sheet with `SUMIFS`/cell arithmetic
3. **Phase 3 (Step 1)** — Calculate the 95th-percentile high-risk threshold and apply the `High Risk Flag` column
4. **Phase 3 (Step 2)** — Pull Suspicious Transaction Frequency and Account Activity Ratio onto the Dashboard
5. **Phase 3 (Step 3)** — Build the 5 categorical PivotTables on the hidden Pivot Engine sheet
6. **Phase 4** — Convert each PivotTable into a PivotChart, cut and paste onto the Dashboard

---

## 12. Tech Stack

`Power Query` · `SUMIFS / COUNTIF / COUNTA / AVERAGE / PERCENTILE.INC` · `PivotTables / PivotCharts` · `Slicers` · Excel 2016+

---

