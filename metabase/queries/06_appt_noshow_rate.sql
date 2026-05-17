-- Descripcion: Tasa no-show = citas con status='no_show'/'noshow' / total citas pasadas.
-- Tablas: ghl_appointments
-- Refresh rate: tiempo real

SELECT
  ROUND(
    100.0 * COUNT(CASE WHEN status IN ('no_show','noshow','no-show') THEN 1 END)
    / NULLIF(COUNT(*), 0),
    1
  ) AS noshow_rate_pct
FROM ghl_appointments
WHERE start_time < NOW()
  [[ AND location_id = {{location_id}} ]]
  [[ AND start_time >= {{date_from}} ]]
  [[ AND start_time <= {{date_to}} ]]
