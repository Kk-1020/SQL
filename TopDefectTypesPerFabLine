SELECT
  wl.fab_line,
  fl.location,
  dl.defect_type,
  dl.layer,
  SUM(dl.count) AS total_defects,
  COUNT(DISTINCT wl.lot_id) AS affected_lots
FROM defect_log dl
INNER JOIN wafer_lots wl
  ON dl.lot_id = wl.lot_id
LEFT JOIN fab_lines fl
  ON wl.fab_line = fl.fab_line
GROUP BY wl.fab_line, fl.location, dl.defect_type, dl.layer
ORDER BY wl.fab_line, total_defects DESC;
