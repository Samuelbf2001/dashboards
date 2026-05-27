\echo '── ghl_locations'
SELECT location_id, client_name, client_slug, active, metabase_dashboard_id, created_at
FROM ghl_locations
ORDER BY created_at;

\echo '── Coherencia: location_ids en dim_contacts que ya están registrados'
SELECT
  c.location_id,
  COUNT(DISTINCT c.contact_id) AS contactos,
  l.client_name,
  l.active
FROM dim_contacts c
LEFT JOIN ghl_locations l USING (location_id)
GROUP BY c.location_id, l.client_name, l.active
ORDER BY contactos DESC;
