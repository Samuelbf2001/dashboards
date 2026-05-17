#!/usr/bin/env bash
# MB-01 [BLOQUEANTE] - Dashboards cargan sin error
# Criterio: todos los cards muestran datos, sin "Query Error" en la API
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${MB_SITE_URL:?Requerida: MB_SITE_URL}"
: "${METABASE_ADMIN_USER:?Requerida: METABASE_ADMIN_USER}"
: "${METABASE_ADMIN_PASSWORD:?Requerida: METABASE_ADMIN_PASSWORD}"

echo "=== MB-01: Dashboards load without errors ==="

# Obtener session token de Metabase
SESSION=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"${METABASE_ADMIN_USER}\", \"password\": \"${METABASE_ADMIN_PASSWORD}\"}" \
  "${MB_SITE_URL}/api/session" 2>/dev/null | jq -r '.id // empty')

if [[ -z "$SESSION" ]]; then
  echo "  ERROR: No se pudo obtener session de Metabase"
  echo "STATUS: FAIL (BLOQUEANTE) - No se puede autenticar en Metabase"
  exit 1
fi

echo "  Session obtenida: ${SESSION:0:8}..."

# Obtener lista de dashboards
dashboards=$(curl -s \
  -H "X-Metabase-Session: ${SESSION}" \
  "${MB_SITE_URL}/api/dashboard" 2>/dev/null | jq -r '.[].id' 2>/dev/null)

if [[ -z "$dashboards" ]]; then
  echo "  No hay dashboards creados aun. Crear los 6 dashboards requeridos primero."
  echo "STATUS: FAIL (BLOQUEANTE) - 0 dashboards encontrados"
  exit 1
fi

echo "  Dashboards encontrados: $(echo "$dashboards" | wc -l)"
PASS=0
FAIL=0

for dashboard_id in $dashboards; do
  # Obtener el dashboard y verificar que no hay errores en los cards
  result=$(curl -s \
    -H "X-Metabase-Session: ${SESSION}" \
    "${MB_SITE_URL}/api/dashboard/${dashboard_id}" 2>/dev/null)

  name=$(echo "$result" | jq -r '.name // "unknown"')
  card_count=$(echo "$result" | jq '.ordered_cards | length // 0')

  echo "  Dashboard #${dashboard_id}: '${name}' (${card_count} cards)"

  # Ejecutar cada card del dashboard para verificar que no hay Query Error
  card_ids=$(echo "$result" | jq -r '.ordered_cards[].card.id // empty' 2>/dev/null)
  card_errors=0

  for card_id in $card_ids; do
    card_result=$(curl -s -X POST \
      -H "X-Metabase-Session: ${SESSION}" \
      -H "Content-Type: application/json" \
      -d '{"ignore_cache": false, "collection_preview": false}' \
      "${MB_SITE_URL}/api/card/${card_id}/query" 2>/dev/null)

    has_error=$(echo "$card_result" | jq -r '.error // empty')
    if [[ -n "$has_error" ]]; then
      echo "    Card #${card_id}: ERROR - ${has_error}"
      card_errors=$((card_errors + 1))
    fi
  done

  if [[ $card_errors -eq 0 ]]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "    ${card_errors} cards con error en dashboard '${name}'"
  fi
done

echo ""
echo "  Dashboards OK: ${PASS} | Con errores: ${FAIL}"

if [[ $FAIL -gt 0 ]]; then
  echo "STATUS: FAIL (BLOQUEANTE)"
  exit 1
fi

echo "STATUS: PASS"
exit 0
