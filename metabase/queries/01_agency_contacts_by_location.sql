-- Descripcion: Total de contactos activos agrupados por location_id para comparar clientes.
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT
  location_id,
  COUNT(DISTINCT contact_id) AS total_contactos
FROM mv_unified_attribution
WHERE 1=1
  [[ AND contact_created_at >= {{date_from}} ]]
  [[ AND contact_created_at <= {{date_to}} ]]
GROUP BY location_id
ORDER BY total_contactos DESC
