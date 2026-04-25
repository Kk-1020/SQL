SELECT
  wl.lot_id,
  p.product_name,
  wl.fab_line,
  wl.start_date,
  ROUND(yr.good_dies * 100.0 / yr.total_dies, 1) AS yield_pct,
  p.target_yield,
  CASE
    WHEN (yr.good_dies * 100.0 / yr.total_dies) < p.target_yield - 10
      THEN 'critical'
    WHEN (yr.good_dies * 100.0 / yr.total_dies) < p.target_yield
      THEN 'below target'
    ELSE 'on target'
  END AS status
FROM wafer_lots wl
INNER JOIN products p ON wl.product_id = p.product_id
INNER JOIN yield_results yr ON wl.lot_id = yr.lot_id
WHERE yr.test_stage = 'final'
  AND yr.good_dies * 100.0 / yr.total_dies < p.target_yield
ORDER BY yield_pct ASC;
