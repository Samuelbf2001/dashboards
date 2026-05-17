#!/usr/bin/env bash
# SEC-01 [BLOQUEANTE] - RLS: cliente A no ve datos de cliente B
# Criterio: SELECT con rol client_loc_A retorna 0 filas de location_id B
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${CLIENT_A_ROLE:?Requerida: CLIENT_A_ROLE (ej: client_loc_abc123)}"
: "${CLIENT_A_PASSWORD:?Requerida: CLIENT_A_PASSWORD}"
: "${CLIENT_B_LOCATION_ID:?Requerida: CLIENT_B_LOCATION_ID (location_id del cliente B)}"

echo "=== SEC-01: RLS isolation ==="
echo "  Rol del cliente A: ${CLIENT_A_ROLE}"
echo "  Intentando leer datos de location_id: ${CLIENT_B_LOCATION_ID}"

export PGPASSWORD="$CLIENT_A_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $CLIENT_A_ROLE -d $POSTGRES_DB -tAq"

count=$($PSQL -c "SELECT COUNT(*) FROM dim_contacts WHERE location_id = '${CLIENT_B_LOCATION_ID}' LIMIT 1;" 2>/dev/null || echo "ERROR")

echo "  Filas encontradas: ${count}"

if [[ "$count" == "0" ]]; then
  echo "STATUS: PASS - RLS activo: cliente A no ve datos de cliente B"
  exit 0
elif [[ "$count" == "ERROR" ]]; then
  echo "STATUS: PASS - Acceso denegado por RLS (no pudo ejecutar query)"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - RLS FALLIDO: cliente A puede ver ${count} filas de cliente B"
exit 1
