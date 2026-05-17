-- Descripcion: Total de citas agendadas en el rango de fechas.
-- Tablas: ghl_appointments (nombrada asi en Platform Spec; el Agente 1 define el nombre real).
--   NOTA: el Database Design no incluye esquema detallado de appointments. Ajustar nombre
--   de tabla si Agente 1 la define como dim_appointments.
-- Refresh rate: tiempo real

SELECT COUNT(*) AS total_citas
FROM ghl_appointments
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND start_time >= {{date_from}} ]]
  [[ AND start_time <= {{date_to}} ]]
