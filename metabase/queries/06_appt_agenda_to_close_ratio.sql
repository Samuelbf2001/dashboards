-- Descripcion: Ratio agenda -> cierre. Contactos con al menos una cita que tienen oportunidad won
--   / total contactos con al menos una cita. Mide cuantos se convierten tras una cita.
-- Tablas: ghl_appointments JOIN dim_opportunities
-- Refresh rate: cada hora

SELECT
  COUNT(DISTINCT a.contact_id) AS contactos_con_cita,
  COUNT(DISTINCT CASE WHEN o.status = 'won' THEN a.contact_id END) AS contactos_con_cita_y_won,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN o.status = 'won' THEN a.contact_id END)
    / NULLIF(COUNT(DISTINCT a.contact_id), 0),
    1
  ) AS ratio_agenda_a_cierre_pct
FROM ghl_appointments a
LEFT JOIN dim_opportunities o
  ON o.contact_id = a.contact_id
  AND o.is_current = TRUE
WHERE 1=1
  [[ AND a.location_id = {{location_id}} ]]
  [[ AND a.start_time >= {{date_from}} ]]
  [[ AND a.start_time <= {{date_to}} ]]
