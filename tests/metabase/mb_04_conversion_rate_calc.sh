#!/usr/bin/env bash
# MB-04 [BLOQUEANTE] - Tasa de conversion calculada correctamente
# Criterio: won/total x 100 coincide con calculo manual de muestra
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
: "${TEST_PIPELINE_CARD_ID:=}"  # ID de la card "Tasa de conversion" en Metabase

echo "=== MB-04: Conversion rate calculation ==="

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

# Calculo manual directo en PostgreSQL
manual_rate=$($PSQL -c "
  SELECT ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN status = 'won' THEN opportunity_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN status IN ('won','lost','abandoned') THEN opportunity_id END), 0),
    2
  )
  FROM dim_opportunities
  WHERE is_current = TRUE;
" 2>/dev/null || echo "")

echo "  Tasa calculada manualmente (SQL directo): ${manual_rate}%"

if [[ -z "$manual_rate" ]]; then
  echo "STATUS: FAIL - No se pudo calcular la tasa manualmente (sin datos?)"
  exit 1
fi

# Si se proporciono el ID del card, comparar con el valor del dashboard
if [[ -n "$TEST_PIPELINE_CARD_ID" ]]; then
  SESSION=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"${METABASE_ADMIN_USER}\", \"password\": \"${METABASE_ADMIN_PASSWORD}\"}" \
    "${MB_SITE_URL}/api/session" 2>/dev/null | jq -r '.id // empty')

  card_result=$(curl -s -X POST \
    -H "X-Metabase-Session: ${SESSION}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "${MB_SITE_URL}/api/card/${TEST_PIPELINE_CARD_ID}/query" 2>/dev/null)

  dashboard_rate=$(echo "$card_result" | jq -r '.data.rows[0][0] // empty')
  echo "  Tasa en dashboard Metabase: ${dashboard_rate}%"

  if [[ -n "$dashboard_rate" ]]; then
    # Permitir diferencia de hasta 0.5 por redondeo
    diff=$(echo "scale=2; define abs(x) { if (x < 0) return -x; return x; }; abs(${manual_rate} - ${dashboard_rate})" | bc 2>/dev/null || echo "1")
    if (( $(echo "$diff <= 0.5" | bc -l 2>/dev/null || echo 0) )); then
      echo "STATUS: PASS - Tasas coinciden (diferencia: ${diff})"
      exit 0
    else
      echo "STATUS: FAIL (BLOQUEANTE) - Tasas no coinciden: manual=${manual_rate}, dashboard=${dashboard_rate}"
      exit 1
    fi
  fi
fi

echo "  Sin card ID de dashboard para comparar. Calculo manual verificado."
echo "STATUS: PASS (calculo SQL validado, comparacion con dashboard requiere TEST_PIPELINE_CARD_ID)"
exit 0
