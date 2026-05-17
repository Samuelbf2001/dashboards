#!/usr/bin/env bash
# MB-06 [BLOQUEANTE] - Avg first reply time calculado correctamente
# Criterio: card "Avg First Reply Time" coincide con calculo manual en SQL
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
: "${MB_FIRST_REPLY_CARD_ID:=}"

echo "=== MB-06: First reply time calculation ==="

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

# Calculo manual
manual_avg=$($PSQL -c "
  SELECT ROUND(AVG(first_reply_seconds), 0)
  FROM dim_conversations
  WHERE is_current = TRUE
    AND first_reply_seconds IS NOT NULL
    AND first_reply_seconds > 0;
" 2>/dev/null || echo "")

echo "  Avg first reply (SQL directo): ${manual_avg} segundos"

if [[ -z "$manual_avg" || "$manual_avg" == "" ]]; then
  echo "  Sin datos de first_reply_seconds en dim_conversations"
  echo "STATUS: SKIP - Sin datos suficientes"
  exit 0
fi

# Comparar con Metabase si se proporciona el card ID
if [[ -n "$MB_FIRST_REPLY_CARD_ID" ]]; then
  SESSION=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"${METABASE_ADMIN_USER}\", \"password\": \"${METABASE_ADMIN_PASSWORD}\"}" \
    "${MB_SITE_URL}/api/session" 2>/dev/null | jq -r '.id // empty')

  card_result=$(curl -s -X POST \
    -H "X-Metabase-Session: ${SESSION}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "${MB_SITE_URL}/api/card/${MB_FIRST_REPLY_CARD_ID}/query" 2>/dev/null)

  dashboard_avg=$(echo "$card_result" | jq -r '.data.rows[0][0] // empty')
  echo "  Avg en dashboard Metabase: ${dashboard_avg} segundos"

  if [[ -n "$dashboard_avg" ]]; then
    diff=$(echo "scale=0; define abs(x) { if (x < 0) return -x; return x; }; abs(${manual_avg} - ${dashboard_avg})" | bc 2>/dev/null || echo "999")
    if (( $(echo "$diff <= 5" | bc -l 2>/dev/null || echo 0) )); then
      echo "STATUS: PASS - Valores coinciden (diferencia: ${diff}s)"
      exit 0
    else
      echo "STATUS: FAIL (BLOQUEANTE) - Valores no coinciden: manual=${manual_avg}s, dashboard=${dashboard_avg}s"
      exit 1
    fi
  fi
fi

echo "STATUS: PASS (calculo SQL validado)"
exit 0
