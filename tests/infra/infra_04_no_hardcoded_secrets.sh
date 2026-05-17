#!/usr/bin/env bash
# INFRA-04 [BLOQUEANTE] - Variables de entorno nunca en codigo
# Criterio: grep recursivo de patrones de secretos en archivos de codigo fuente
#   sin resultados hardcodeados. Excluye .env.example y este script.
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${REPO_ROOT:=$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$0")/../..")}"

echo "=== INFRA-04: No hardcoded secrets ==="
echo "  Repositorio: ${REPO_ROOT}"

PATTERNS=(
  "password\s*=\s*['\"][^'\"$\{]"
  "secret\s*=\s*['\"][^'\"$\{]"
  "api_key\s*=\s*['\"][^'\"$\{]"
  "apikey\s*=\s*['\"][^'\"$\{]"
  "POSTGRES_PASSWORD\s*=\s*[a-zA-Z0-9]"
  "N8N_BASIC_AUTH_PASSWORD\s*=\s*[a-zA-Z0-9]"
  "MB_EMBEDDING_SECRET_KEY\s*=\s*[a-zA-Z0-9]"
  "GHL_API_KEY\s*=\s*[a-zA-Z0-9]"
  "WEBHOOK_SECRET\s*=\s*[a-zA-Z0-9]"
)

EXCLUDE_PATTERNS=(
  "\.env\.example"
  "DEPLOYMENT_RUNBOOK\.md"
  "OPERATIONS_GUIDE\.md"
  "CLIENT_ONBOARDING\.md"
  "infra_04_no_hardcoded_secrets\.sh"
  "\.git/"
  "node_modules/"
)

FOUND=0

for pattern in "${PATTERNS[@]}"; do
  # Build exclude args
  exclude_args=""
  for excl in "${EXCLUDE_PATTERNS[@]}"; do
    exclude_args="${exclude_args} --exclude-dir=$(dirname $excl 2>/dev/null || echo $excl)"
  done

  results=$(grep -rin -E "$pattern" "$REPO_ROOT" \
    --exclude="*.env.example" \
    --exclude="infra_04_no_hardcoded_secrets.sh" \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    2>/dev/null || true)

  if [[ -n "$results" ]]; then
    echo "  POSIBLE SECRETO HARDCODEADO (patron: ${pattern}):"
    echo "$results" | head -5
    FOUND=$((FOUND + 1))
  fi
done

echo ""
if [[ $FOUND -gt 0 ]]; then
  echo "  Se encontraron ${FOUND} patron(es) sospechosos."
  echo "STATUS: FAIL (BLOQUEANTE)"
  exit 1
fi

echo "  No se encontraron secretos hardcodeados."
echo "STATUS: PASS"
exit 0
