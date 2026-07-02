# Bank Analytics: Multi-Tool Loan & Transaction Intelligence

An end-to-end banking analytics project analyzing **loan portfolio performance** and **bank transaction activity** across **Excel, SQL, Power BI, and Tableau**.

Built from two raw banking datasets, the project demonstrates how the same business problem can be solved consistently across multiple analytics platforms using SQL, DAX, LOD expressions, and Power Query to deliver interactive dashboards and business insights.

---

## Dashboard Preview

### Advanced Excel

#### Loan Analytics Dashboard

![Loan Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/advanced-excel/banking.gif)

#### Debit & Credit Analytics Dashboard

![Debit Credit Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/advanced-excel/bank-debit-credit.gif)

---

### Power BI

#### Overview

![Overview](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/power-bi/01_overview.jpg)

#### Branch & Bank

![Branch Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/power-bi/02_branch-bank.jpg)

#### Risk Analytics

![Risk Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/power-bi/03_risk.jpg)

---

### Tableau

#### Loan Analytics Dashboard

![Tableau Dashboard](https://raw.githubusercontent.com/angelvbenit/bank-analytics/refs/heads/main/tableau/dashboard.jpg)

##  Interactive Dashboard

🔗 **Tableau Public:** https://public.tableau.com/app/profile/angelvbenit/viz/banking-dashboard/banking-dashboard
---

## Project Summary

This project transforms two banking datasets into interactive dashboards that help monitor:

- Portfolio growth and loan performance
- Repayment behavior and credit risk
- Branch and product performance
- Debit and credit transaction trends
- High-risk transaction detection using percentile-based anomaly scoring

The same business problem was independently implemented in **Excel, MySQL, Power BI, and Tableau**, with KPIs validated across platforms to ensure consistent business results.

---

## Repository Structure

```text
bank-analytics/
│
├── README.md
├── advanced-excel/
├── sql/
├── power-bi/
└── tableau/
```

---

## Key KPIs

| Area | KPIs |
|------|------|
| Client Portfolio | Total Clients, Active Clients, New Clients, Retention Rate |
| Loan Performance | Total Loan Amount, Principal Recovery Rate, Interest Income, Default Rate |
| Business Growth | Loan Growth %, Branch Performance, Product Performance |
| Transaction Analytics | Total Credit, Total Debit, Net Transaction Amount, Credit-to-Debit Ratio |
| Risk Analytics | Delinquency Rate, On-Time Repayment %, High-Risk Transactions |

---

## Tool Highlights

### Advanced Excel

- Power Query + Power Pivot data model
- Star schema with Calendar table
- 23 DAX measures
- Interactive loan and transaction dashboards

### MySQL

- Star-schema loan database
- Window functions, CTEs, CASE statements, and joins
- Dynamic fraud detection using `PERCENT_RANK()`
- Data cleaning and ETL preprocessing

### Power BI

- Live MySQL connection
- Dynamic DAX measures
- Interactive filtering and drill-down analysis
- Percentile-based transaction risk analytics

### Tableau

- Rebuilt KPI model using LOD expressions
- Relationship-aware data modeling
- KPI validation against SQL outputs

---

## Key Insights

- Achieved **99.05% principal recovery** with a **5.00% default rate**, indicating a healthy loan portfolio.
- **71.05% on-time repayment** highlights opportunities to improve collection efficiency.
- Dynamic percentile-based risk scoring adapts automatically as transaction volume and values change.
- Cross-platform implementation ensured KPI consistency across Excel, SQL, Power BI, and Tableau.

---

## Technical Highlights

- Star-schema dimensional modeling
- SQL window functions and Common Table Expressions (CTEs)
- DAX measures and filter context
- Tableau LOD expressions
- Power Query data transformation
- Dynamic percentile-based anomaly detection
- Cross-platform KPI validation

---

## Project Goals

- Build production-style banking analytics dashboards.
- Apply consistent business logic across multiple analytics platforms.
- Demonstrate SQL, dashboarding, data modeling, and business intelligence skills.
- Showcase an end-to-end analytics workflow from raw data to executive reporting.

---

Detailed implementation, SQL scripts, dashboard logic, data-cleaning steps, and methodology are documented inside each tool's individual README.