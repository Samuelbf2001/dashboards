#!/usr/bin/env bash
# SEC-02 [BLOQUEANTE] - RLS: superadmin ve todos los datos
# Criterio: SELECT con rol sixteam_admin retorna filas de multiples location_id
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"
: "${MIN_LOCATIONS:=2}"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

echo "=== SEC-02: Superadmin sees all ==="

distinct_locations=$($PSQL -c "SELECT COUNT(DISTINCT location_id) FROM dim_contacts;" 2>/dev/null || echo 0)

echo "  Locations distintos visibles para sixteam_admin: ${distinct_locations}"

if [[ "$distinct_locations" -ge "$MIN_LOCATIONS" ]]; then
  echo "STATUS: PASS - sixteam_admin ve datos de ${distinct_locations} clientes"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - sixteam_admin solo ve ${distinct_locations} locations (esperado >= ${MIN_LOCATIONS})"
echo "  Asegurarse de que haya datos seed de al menos 2 clientes distintos."
exit 1
