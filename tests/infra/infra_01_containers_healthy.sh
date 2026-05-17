#!/usr/bin/env bash
# INFRA-01 [BLOQUEANTE] - Todos los contenedores estan healthy
# Criterio: docker ps muestra 5/5 containers healthy
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

EXPECTED_CONTAINERS=("postgres" "n8n" "metabase" "traefik" "uptime-kuma")
PASS=0
FAIL=0

echo "=== INFRA-01: Containers healthy ==="

for name in "${EXPECTED_CONTAINERS[@]}"; do
  status=$(docker ps --filter "name=${name}" --format "{{.Status}}" 2>/dev/null | head -1)
  if [[ "$status" == *"healthy"* ]]; then
    echo "  PASS  ${name}: ${status}"
    PASS=$((PASS + 1))
  elif [[ -z "$status" ]]; then
    echo "  FAIL  ${name}: not running"
    FAIL=$((FAIL + 1))
  else
    echo "  FAIL  ${name}: ${status}"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "Resultado: ${PASS}/${#EXPECTED_CONTAINERS[@]} containers healthy"

if [[ $FAIL -gt 0 ]]; then
  echo "STATUS: FAIL (BLOQUEANTE)"
  exit 1
fi

echo "STATUS: PASS"
exit 0
