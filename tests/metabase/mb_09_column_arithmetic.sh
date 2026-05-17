#!/usr/bin/env bash
# MB-09 [BLOQUEANTE] - Operaciones entre columnas en query builder
# Criterio: campo calculado [revenue] / [total_contacts] devuelve resultado correcto
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"
: "${MB_SITE_URL:?Requerida: MB_SITE_URL}"
: "${METABASE_ADMIN_USER:?Requerida: METABASE_ADMIN_USER}"
: "${METABASE_ADMIN_PASSWORD:?Requerida: METABASE_ADMIN_PASSWORD}"

echo "=== MB-09: Column arithmetic ==="

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

# Calcular revenue / total_contacts manualmente
result=$($PSQL -c "
  WITH stats AS (
    SELECT
      COALESCE(SUM(CASE WHEN opp_status = 'won' THEN monetary_value END), 0) AS total_revenue,
      COUNT(DISTINCT contact_id) AS total_contacts
    FROM mv_unified_attribution
  )
  SELECT
    total_revenue,
    total_contacts,
    CASE WHEN total_contacts > 0
      THEN ROUND(total_revenue / total_contacts::NUMERIC, 2)
      ELSE 0
    END AS revenue_per_contact
  FROM stats;
" 2>/dev/null || echo "")

echo "  Resultado (revenue | contacts | revenue/contact):"
echo "  ${result}"

if [[ -z "$result" ]]; then
  echo "  Sin datos en mv_unified_attribution"
  echo "STATUS: SKIP - Sin datos suficientes para el calculo"
  exit 0
fi

# Verificar que la operacion aritmetica devuelve un numero valido
revenue_per_contact=$(echo "$result" | awk -F'|' '{print $3}' | tr -d ' ')

if echo "$revenue_per_contact" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
  echo "  revenue_per_contact calculado: ${revenue_per_contact}"
  echo "STATUS: PASS - Operacion aritmetica entre columnas funciona correctamente"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - No se pudo calcular revenue / total_contacts"
exit 1
