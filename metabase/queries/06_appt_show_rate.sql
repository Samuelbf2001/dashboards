-- Descripcion: Tasa show = citas con status='showed'/'completed' / total citas pasadas.
-- Tablas: ghl_appointments
-- Refresh rate: tiempo real

SELECT
  ROUND(
    100.0 * COUNT(CASE WHEN status IN ('showed','completed','attended') THEN 1 END)
    / NULLIF(COUNT(*), 0),
    1
  ) AS show_rate_pct
FROM ghl_appointments
WHERE start_time < NOW()
  [[ AND location_id = {{location_id}} ]]
  [[ AND start_time >= {{date_from}} ]]
  [[ AND start_time <= {{date_to}} ]]
