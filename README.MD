# Bank Analytics: Multi-Tool Loan & Transaction Intelligence

An end-to-end analytics capstone project analyzing microfinance loan performance and bank transaction activity across **Excel, SQL, Power BI, and Tableau** showcasing the same business problem solved four different ways, from raw data to interactive dashboards.

---

## 1. Project Summary

This project turns two raw banking datasets — a **6-sheet loan portfolio** (1,000 clients, 2,000 loans, 2015–2023) and a **10K–100K row transaction ledger** — into decision-ready dashboards. The goal: give lending and operations teams a clear read on **portfolio health, repayment risk, and transaction-level fraud signals**, and demonstrate the same KPI logic implemented consistently across Excel, MySQL, Power BI, and Tableau.

Each tool was built to solve the problem in its own idiomatic way (DAX measures, SQL window functions, LOD expressions, PERCENTILE-based risk scoring), and results were cross-validated against each other for accuracy.

---

## 2. Repository Structure

```
bank-analytics/
│
├── README.md  ← Executive summary, tool comparision, insights, key findings & solutions
│
├── advanced-excel/
│   ├── Dashboard files
│   └── README.md
│
├── sql/
│   ├── Scripts
│   └── README.md
│
├── power-bi/
│   ├── PBIX
│   └── README.md
│
└── tableau/
    ├── Workbook
    └── README.md
```

---
## 3. Dashboard Preview

### Advanced Excel

#### Loan Analytics Dashboard

![Loan Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/advanced-excel/banking.gif)

#### Debit & Credit Analytics Dashboard

![Debit Credit Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/advanced-excel/bank-debit-credit.gif)

---

### Power BI

#### Overview (Page - 1)

![Overview](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/power-bi/01_overview.jpg)

#### Branch & Bank (Page - 2)

![Branch Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/power-bi/02_branch-bank.jpg)

#### Risk Analytics (Page - 3)

![Risk Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/power-bi/03_risk.jpg)

---

### Tableau

#### Loan Analytics Dashboard

![Tableau Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/tableau/dashboard.jpg)

---

## 4. KPI List

| KPI | Business Purpose |
|---|---|
| **Total / Active / New Clients** | Client base size and portfolio engagement |
| **Client Retention Rate** | Year-over-year client growth |
| **Total Loan / Funded Amount** | Portfolio scale and disbursement accuracy |
| **Loan Growth %** | Business expansion or contraction signal |
| **Principal Recovery Rate** | Collection efficiency |
| **Interest Income** | Core lending revenue |
| **Default Rate / Delinquency Rate** | Credit risk — loss events and early warnings |
| **On-Time Repayment %** | Borrower repayment quality |
| **Branch & Product Performance** | Where volume and profitability concentrate |
| **Credit-to-Debit Ratio / Net Transaction Amount** | Liquidity and cash-flow health |
| **High-Risk Transaction Flag (95th percentile)** | Statistically-driven fraud/anomaly detection |

23 measures in Excel/Power BI, 17 KPIs in Tableau, and 17 + 13 KPIs across the two SQL projects — all reconciled to the same underlying numbers.

---

## 5. Excel Dashboard

Built on **Power Query + Power Pivot + DAX**, using a star-schema data model (5 relationships, dedicated Calendar table) with 23 live measures.

- **Loan Dashboard:** ₹52.36M disbursed, ₹53.86M collected, 99.05% principal recovery, 5.00% default rate, 71.05% on-time repayment. Top branches: Dhuri, Muktsar, Behror.
- **Debit/Credit Dashboard:** 10,000 transactions, ₹127.6M credited vs ₹127.3M debited (1.00x ratio), with a self-adjusting **95th-percentile risk threshold** flagging the top 5% (5,000) of transactions as high-risk , no hardcoded dollar cutoffs.

---

## 6. Tableau Dashboard

Rebuilds the Excel KPI model using **LOD expressions and a left-joined data model**, with `Dim Client` deliberately kept as a standalone source to correctly preserve the full 1,000-client base (a join-vs-relationship modeling nuance not present in Excel/Power BI).

All 17 KPIs were validated line-by-line against the SQL output — **100% match** across every metric, from Total Clients (1,000) down to Interest Income (₹5.06M).

---

## 7. Power BI Dashboard

Connects live to a **MySQL backend via ODBC**, with every KPI rebuilt as a DAX measure (not a static SQL aggregate) so the dashboard responds instantly to slicers , branch, bank, date, and transaction type all filter every visual in real time.

Handles Excel-serial date conversion, text-to-numeric casting, and a dynamic `PERCENTILE.INC`-based risk score across the full **100,000-transaction** dataset, surfaced in a dedicated high-risk transactions table for compliance review.

---

## 8. SQL Query Image

**Two MySQL 8.0 databases** power the loan and transaction analytics:

- **Loan schema** — star schema (`fact_loan`, `fact_repayment`, `dim_client`, `dim_branch`, `dim_product`), 17 KPIs using `CASE WHEN`, `JOIN`, `NULLIF`, and dynamic year comparisons.
- **Transaction schema** — single fact table (`debitcredit`), 13 KPIs using `PERCENT_RANK()` for fraud detection, `LAG()` for month-over-month growth, and CTEs for readability.

Common engineering fixes applied: Windows `\r\n` carriage-return stripping, Excel serial-date conversion, and foreign-key–safe reload procedures , all documented with root cause and rule violated in each tool's individual README.

---

## 9. Key Takeaways

**Business Insights**
- The loan book is healthy overall (99% principal recovery, 5% default) but **on-time repayment at 71%** signals room to tighten collections before loans slip into delinquency.
- Transaction-level risk scoring shows a **stable, evenly-distributed 6-branch network** — no single branch is a fraud or volume outlier, which is itself a useful baseline finding.
- Statistically-driven thresholds (95th percentile) consistently outperform hardcoded fraud rules — they self-adjust as data volume and typical transaction size grow.

**Challenges**
- **Cross-tool consistency:** Tableau's join model and Excel/Power BI's relationship model handle unmatched dimension rows differently (870 vs 1,000 clients) — required a standalone-source workaround in Tableau to match.
- **Data quality gaps:** hidden Windows line-ending characters, Excel serial dates, and a partial-month data artifact (Dec 2024) all silently broke KPIs until explicitly diagnosed and fixed.
- **Filter-context traps:** Power BI KPIs built on static SQL aggregates ignored slicers entirely until rewritten as DAX `CALCULATE()` measures — a reminder that BI-layer logic and DB-layer logic aren't interchangeable.

**Future Recommendations**
- Automate the `\r` and date-cleaning fixes upstream (in the ETL/load step) rather than post-load, to remove a recurring failure point.
- Extend the 95th-percentile risk model with a second-tier (e.g. 99th percentile "critical risk") band for tiered compliance review.
- Add a client-level cohort/vintage analysis to see how retention and default rates evolve by loan origination year, not just year-over-year totals.

---

*Full build logic, error logs, and step-by-step methodology for each tool are documented in their respective folder READMEs.*