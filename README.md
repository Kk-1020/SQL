# Semiconductor Manufacturing Yield & Defect Analysis

A SQL portfolio project modeled after a semiconductor wafer fabrication environment — designed to demonstrate intermediate SQL skills relevant to a Database / Software Engineer role at a company like Texas Instruments.

---

## Project overview

This project defines a normalized relational database schema representing core manufacturing operations: production lots, yield test results, defect logging, and fab line capacity. Five analytical queries demonstrate practical, real-world data extraction patterns across multiple joined tables.

---

## Schema

Five tables, designed with referential integrity in mind:

| Table | Description |
|---|---|
| `wafer_lots` | Production lot records — links a product to a fab line and tracks wafer count and start date |
| `products` | Product catalog with family classification, process node (nm), and target yield percentage |
| `yield_results` | Die-level pass/fail counts per test stage per lot (e.g., final, sort) |
| `defect_log` | Defect type and layer data per lot, used for root cause analysis |
| `fab_lines` | Fab location, process node capability, and weekly wafer capacity |

### Entity relationships

```
products ──< wafer_lots >──< yield_results
                  │
                  └──< defect_log

fab_lines ──< wafer_lots
```

---

## Queries

### 1. Yield vs. target by product
**Concepts:** `INNER JOIN`, `GROUP BY`, `AVG`, `HAVING`

Joins three tables to compute average final-stage yield per product, filtered to lots with a minimum sample size. Surfaces which products are missing their yield targets.

```sql
SELECT
  p.product_name,
  p.family,
  p.target_yield,
  ROUND(AVG(yr.good_dies * 100.0 / yr.total_dies), 1) AS avg_yield_pct,
  COUNT(DISTINCT wl.lot_id) AS lots_tested
FROM products p
INNER JOIN wafer_lots wl ON p.product_id = wl.product_id
INNER JOIN yield_results yr ON wl.lot_id = yr.lot_id
WHERE yr.test_stage = 'final'
GROUP BY p.product_id, p.product_name, p.family, p.target_yield
HAVING COUNT(DISTINCT wl.lot_id) >= 2
ORDER BY avg_yield_pct DESC;
```

---

### 2. Top defect types per fab line
**Concepts:** `LEFT JOIN`, `GROUP BY`, `SUM`, `ORDER BY`

Aggregates defect counts by fab line, defect type, and layer. Left join preserves fab lines with no recorded defects. Used for manufacturing root cause analysis.

```sql
SELECT
  wl.fab_line,
  fl.location,
  dl.defect_type,
  dl.layer,
  SUM(dl.count) AS total_defects,
  COUNT(DISTINCT wl.lot_id) AS affected_lots
FROM defect_log dl
INNER JOIN wafer_lots wl ON dl.lot_id = wl.lot_id
LEFT JOIN fab_lines fl ON wl.fab_line = fl.fab_line
GROUP BY wl.fab_line, fl.location, dl.defect_type, dl.layer
ORDER BY wl.fab_line, total_defects DESC;
```

---

### 3. Lots below yield threshold
**Concepts:** `INNER JOIN`, `WHERE`, derived column, `CASE`

Uses a `CASE` expression to categorize each lot as `critical`, `below target`, or `on target` relative to its product's yield target. Enables prioritized rework queues.

```sql
SELECT
  wl.lot_id,
  p.product_name,
  wl.fab_line,
  wl.start_date,
  ROUND(yr.good_dies * 100.0 / yr.total_dies, 1) AS yield_pct,
  p.target_yield,
  CASE
    WHEN (yr.good_dies * 100.0 / yr.total_dies) < p.target_yield - 10 THEN 'critical'
    WHEN (yr.good_dies * 100.0 / yr.total_dies) < p.target_yield     THEN 'below target'
    ELSE 'on target'
  END AS status
FROM wafer_lots wl
INNER JOIN products p ON wl.product_id = p.product_id
INNER JOIN yield_results yr ON wl.lot_id = yr.lot_id
WHERE yr.test_stage = 'final'
  AND yr.good_dies * 100.0 / yr.total_dies < p.target_yield
ORDER BY yield_pct ASC;
```

---

### 4. Fab line utilization summary
**Concepts:** `LEFT JOIN`, `COUNT`, `SUM`, `GROUP BY`, derived utilization %

Calculates rolling 30-day wafer throughput vs. capacity per fab line. Left join ensures lines with no recent activity still appear. Supports capacity planning decisions.

```sql
SELECT
  fl.fab_line,
  fl.location,
  fl.node_nm,
  fl.capacity_wpw,
  COUNT(DISTINCT wl.lot_id) AS active_lots,
  SUM(wl.wafer_count) AS total_wafers,
  ROUND(SUM(wl.wafer_count) * 100.0 / fl.capacity_wpw, 1) AS utilization_pct
FROM fab_lines fl
LEFT JOIN wafer_lots wl
  ON fl.fab_line = wl.fab_line
  AND wl.start_date >= DATE('now', '-30 days')
GROUP BY fl.fab_line, fl.location, fl.node_nm, fl.capacity_wpw
ORDER BY utilization_pct DESC;
```

---

### 5. Product family yield trend by month
**Concepts:** `strftime`, `GROUP BY` on date period, `AVG`, multi-table join

Buckets final yield data by calendar month and product family to enable time-series trend analysis. Useful for spotting process regressions or improvements over time.

```sql
SELECT
  strftime('%Y-%m', yr.tested_date) AS month,
  p.family,
  COUNT(DISTINCT wl.lot_id) AS lots,
  ROUND(AVG(yr.good_dies * 100.0 / yr.total_dies), 2) AS avg_yield
FROM yield_results yr
INNER JOIN wafer_lots wl ON yr.lot_id = wl.lot_id
INNER JOIN products p ON wl.product_id = p.product_id
WHERE yr.test_stage = 'final'
GROUP BY month, p.family
ORDER BY month, p.family;
```

---

## SQL concepts covered

| Concept | Queries |
|---|---|
| `INNER JOIN` across 3 tables | 1, 3, 5 |
| `LEFT JOIN` (preserve all rows) | 2, 4 |
| `GROUP BY` with aggregation | 1, 2, 4, 5 |
| `HAVING` for post-aggregation filter | 1 |
| `CASE` expression for categorization | 3 |
| Derived / calculated columns | 3, 4 |
| Date bucketing with `strftime` | 5 |
| Rolling window with `DATE('now', '-N days')` | 4 |

---

## Compatibility

All queries are written in standard SQL and tested against **SQLite**. They are compatible with PostgreSQL and MySQL with minor adjustments:

- Replace `strftime('%Y-%m', date_col)` with `TO_CHAR(date_col, 'YYYY-MM')` in PostgreSQL
- Replace `DATE('now', '-30 days')` with `CURRENT_DATE - INTERVAL '30 days'` in PostgreSQL / MySQL

---

## Files

| File | Description |
|---|---|
| `README.md` | This document |
| `queries.sql` | All five queries with schema DDL and sample data |

---

## Author

Portfolio project for Software / Database Engineer application.  
Designed to reflect manufacturing data patterns common in semiconductor companies.
