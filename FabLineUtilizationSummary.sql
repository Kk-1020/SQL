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
