# ADVANCED EXCEL
# Banking Dashboard: Power Query, Data Model & DAX KPIs

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
