SELECT
  p.product_name,
  p.family,
  p.target_yield,
  ROUND(AVG(yr.good_dies * 100.0 / yr.total_dies), 1) AS avg_yield_pct,
  COUNT(DISTINCT wl.lot_id) AS lots_tested
FROM products p
INNER JOIN wafer_lots wl
  ON p.product_id = wl.product_id
INNER JOIN yield_results yr
  ON wl.lot_id = yr.lot_id
WHERE yr.test_stage = 'final'
GROUP BY p.product_id, p.product_name, p.family, p.target_yield
HAVING COUNT(DISTINCT wl.lot_id) >= 2
ORDER BY avg_yield_pct DESC;
