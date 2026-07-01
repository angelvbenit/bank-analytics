# Banking Dashboard: Tableau Public
**Tool:** Tableau Public (Desktop Edition)

---

## 1. Project Overview

This Tableau dashboard is part of a multi-tool banking analytics capstone project built using a raw 6-sheet Excel dataset. The dashboard replicates and extends the Excel Power Pivot KPI model using Tableau's calculated fields, LOD expressions, and join-based data modeling.

---

## 2. Data Source

**Sheets used:** Fact Loan, Fact Repayment, Dim Client, Dim Branch, Dim Product
**Sheet excluded:** Final Fact (pre-joined denormalized table — excluded to prevent double-counting)

**Row counts:**
| Table | Rows |
|---|---|
| Dim Client | 1,000 |
| Dim Branch | 180 |
| Dim Product | 11 |
| Fact Loan | 2,000 |
| Fact Repayment | 2,000 |

**Date range:** 2015–2023 (Disbursement Date)

---

## 3. Data Model (Joins)

Fact Loan is the center table. All other tables join to it via Left Join.

| Join | Left Table | Right Table | Key |
|---|---|---|---|
| J1 | Fact Loan | Fact Repayment | Account ID |
| J2 | Fact Loan | Dim Product | Product Id |
| J3 | Fact Loan | Dim Branch | BranchID |

**Dim Client** is connected as a **separate, standalone data source** (not joined to the main source). This was a deliberate architectural decision, see Section 6 for explanation.

---

## 4. Data Type Fixes Applied

The following columns required manual type correction in the Data Source tab before any calculated fields were created:

| Column | Issue | Fix Applied |
|---|---|---|
| Disbursement Date | Imported as String | Changed to Date |
| Is Default Loan | Imported as Number | Changed to String (values are Y/N) |
| Is Delinquent Loan | Imported as Number | Changed to String (values are Y/N) |
| Client id | Left as Number | Left as Number (changing to String broke the join) |

---

## 5. KPI Calculated Fields (17 Total)

All fields created via Analysis → Create Calculated Field.

### Client KPIs
**Source: Dim Client Standalone**

| KPI | Formula | Expected Value |
|---|---|---|
| Total Clients | `COUNTD([Client id])` | 1,000 |

**Source: Fact Loan+ (main joined source)**

| KPI | Formula | Expected Value |
|---|---|---|
| Active Clients | `COUNTD(IF [Loan Status] = "Active" THEN [Client id] END)` | 324 |
| New Clients | `COUNTD(IF [Disbursement Date] = {FIXED [Client id] : MIN([Disbursement Date])} THEN [Client id] END)` | 870 |
| Client Retention Rate | `COUNTD(IF YEAR([Disbursement Date]) = {FIXED : MAX(YEAR([Disbursement Date]))} THEN [Client id] END) / COUNTD(IF YEAR([Disbursement Date]) = {FIXED : MAX(YEAR([Disbursement Date]))} - 1 THEN [Client id] END)` | 110.20% |

### Loan Volume KPIs

| KPI | Formula | Expected Value |
|---|---|---|
| Total Loan Amount | `SUM([Loan Amount])` | ₹52.36M |
| Total Funded Amount | `SUM([Funded Amount])` | ₹52.36M |
| Avg Loan Size | `AVG([Loan Amount])` | ₹26.18K |
| Loan Growth % | `(SUM(IF YEAR([Disbursement Date]) = {FIXED : MAX(YEAR([Disbursement Date]))} THEN [Loan Amount] END) - SUM(IF YEAR([Disbursement Date]) = {FIXED : MAX(YEAR([Disbursement Date]))} - 1 THEN [Loan Amount] END)) / SUM(IF YEAR([Disbursement Date]) = {FIXED : MAX(YEAR([Disbursement Date]))} - 1 THEN [Loan Amount] END)` | 16.18% |

### Repayment & Income KPIs

| KPI | Formula | Expected Value |
|---|---|---|
| Total Repayments | `SUM([Total Pymnt])` | ₹53.86M |
| Principal Recovery Rate | `SUM([Total Rec Prncp]) / SUM([Loan Amount])` | 99.05% |
| Interest Income | `SUM([Total Rrec int])` | ₹5.06M |

### Risk KPIs

| KPI | Formula | Expected Value |
|---|---|---|
| Default Rate | `COUNTD(IF [Is Default Loan] = "Y" THEN [Account ID] END) / COUNTD([Account ID])` | 5.00% |
| Delinquency Rate | `COUNTD(IF [Is Delinquent Loan] = "Y" THEN [Account ID] END) / COUNTD([Account ID])` | 10.35% |
| On-Time Repayment % | `COUNTD(IF [Repayment Behavior] = "On-Time" THEN [Account ID] END) / COUNTD([Account ID])` | 71.05% |

### Branch & Product KPIs (used in charts)

| KPI | Formula |
|---|---|
| Loan by Branch | `SUM([Loan Amount])` |
| Product Loan Volume | `SUM([Loan Amount])` |
| Product Profitability | `SUM([Total Rrec int])` |

---

## 6. Key Architectural Decisions

### Why Dim Client is a Separate Data Source
Tableau's join model anchors rows to the left (fact) table. Since Fact Loan only contains 2,000 rows covering 870 unique clients (130 clients in Dim Client never took a loan), any COUNTD([Client id]) on the joined table returns 870, not 1,000.

Excel's DAX model uses relationships (not joins), so `COUNTROWS('Dim Client')` reads directly from the dimension table regardless of whether a client has a loan or not.

To replicate this behavior in Tableau, Dim Client was added as a second, independent data source. Total Clients is calculated from this standalone source, giving the correct count of 1,000. Since Total Clients is a static KPI (does not respond to Year/Purpose Category slicers — same behavior as in Excel), the standalone source approach is correct and intentional.

### Why Left Joins (not Inner)
Initial Inner joins reduced the row count and caused Active Clients to show 870 instead of 324. Switching to Left Joins anchored on Fact Loan restored correct values for all KPIs except Total Clients, which required the standalone source solution above.

### Loan Growth % and Client Retention Rate
Both KPIs use dynamic LOD expressions (`{FIXED : MAX(YEAR([Disbursement Date]))}`) to identify the most recent year in the data automatically, then compare it to the prior year. This avoids hardcoding year values and keeps the formulas data-agnostic.

The values produced (Loan Growth % = 16.18%, Client Retention Rate = 110.20%) are cross-validated against the SQL implementation of the same logic, which produces identical results. Both tools agree: the correct year-over-year comparison for 2023 vs 2022 yields these values.

---

## 7. Dashboard Layout

| Zone | Content |
|---|---|
| Top — Title | BANK LOAN PERFORMANCE DASHBOARD |
| Top right — Filters | Year slicer, Purpose Category slicer |
| Row 1 — KPI Band | Total Clients, Active Clients, New Clients, Client Retention Rate, Total Loan Amount, Total Funded Amount, Avg Loan Size |
| Row 2 — KPI Band | Loan Growth %, Total Repayments, Principal Recovery Rate, Interest Income, Default Rate, Delinquency Rate, On-Time Repayment % |
| Middle Left | Branch Loan Distribution (Horizontal Bar) |
| Middle Right | Which Loan Products Are Most Profitable? (Combo: Bar + Line) |
| Bottom Left | Branch Performance Category (Pie/Donut) |
| Bottom Right | Loan Growth Trend 2015–2023 (Line) |


---

## 8. Interactive Filters (Slicers)

| Filter | Field | Type | Scope |
|---|---|---|---|
| Year | YEAR(Disbursement Date) | List | All worksheets using Fact Loan+ data source |
| Purpose Category | Purpose Category (Dim Product) | Multiple Values List | All worksheets using Fact Loan+ data source |

Both filters are set to **Apply to Worksheets → All Using This Data Source** so selecting any value updates all KPI cards and all charts simultaneously.

Note: Total Clients (1,000) does not respond to these filters — this matches Excel behavior where `COUNTROWS('Dim Client')` is not filter-context dependent.

---

## 9. QA Validation

All KPI values verified with no filters applied (Year = All, Purpose Category = All):

| KPI | Tableau Value | SQL Value | Match |
|---|---|---|---|
| Total Clients | 1,000 | 1,000 | ✓ |
| Active Clients | 324 | 324 | ✓ |
| New Clients | 870 | 870 | ✓ |
| Total Loan Amount | ₹52.36M | ₹52,361,121 | ✓ |
| Total Funded Amount | ₹52.36M | ₹52,361,094 | ✓ |
| Avg Loan Size | ₹26.18K | ₹26,180.56 | ✓ |
| Total Repayments | ₹53.86M | ₹53,861,255 | ✓ |
| Principal Recovery Rate | 99.05% | 99.05% | ✓ |
| Interest Income | ₹5.06M | ₹5,055,223 | ✓ |
| Default Rate | 5.00% | 5.00% | ✓ |
| Delinquency Rate | 10.35% | 10.35% | ✓ |
| On-Time Repayment % | 71.05% | 71.05% | ✓ |
| Top Branch | Dhuri ₹4.79M | Dhuri ₹4.79M | ✓ |

---

## 10. How to Open

1. Install Tableau Public (free) from public.tableau.com
2. Open Tableau Public
3. File → Open → select the .twbx file
4. Or view live at: [your Tableau Public URL here]

---

## 11. Dashboard Preview

![Banking Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/main/tableau/dashboard.jpg)

🔗 **Live Dashboard:** [View on Tableau Public](https://public.tableau.com/app/profile/angelvbenit/viz/banking-dashboard/banking-dashboard)

---
