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
