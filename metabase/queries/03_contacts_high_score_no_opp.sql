-- Descripcion: Contactos con ai_lead_score >= 70 que no tienen oportunidad activa.
--   Son leads calificados no trabajados: candidatos a seguimiento inmediato.
-- Tablas: dim_contacts LEFT JOIN dim_opportunities
-- Refresh rate: cada hora

SELECT
  c.contact_id,
  c.first_name,
  c.last_name,
  c.email,
  c.phone,
  c.ai_lead_score,
  c.utm_source_first AS fuente,
  c.ghl_created_at   AS creado_en_ghl
FROM dim_contacts c
LEFT JOIN dim_opportunities o
  ON o.contact_id = c.contact_id
  AND o.is_current = TRUE
  AND o.status = 'open'
WHERE c.is_current = TRUE
  AND c.ai_lead_score >= 70
  AND o.opportunity_id IS NULL
  [[ AND c.location_id = {{location_id}} ]]
ORDER BY c.ai_lead_score DESC
LIMIT 50
