#!/usr/bin/env bash
# INFRA-02 [BLOQUEANTE] - PostgreSQL persiste datos entre reinicios
# Criterio: row insertada en dim_contacts persiste tras docker restart postgres
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

TEST_CONTACT_ID="test_persist_$(date +%s)"

echo "=== INFRA-02: PostgreSQL persistence ==="

# Insertar fila de prueba
echo "  Insertando fila de prueba: contact_id=${TEST_CONTACT_ID}"
$PSQL -c "
  INSERT INTO dim_contacts (contact_id, location_id, valid_from, is_current)
  VALUES ('${TEST_CONTACT_ID}', 'loc_test', NOW(), TRUE)
  ON CONFLICT DO NOTHING;
"

# Reiniciar contenedor postgres
echo "  Reiniciando contenedor postgres..."
docker restart postgres
echo "  Esperando 30 segundos que postgres levante..."
sleep 30

# Verificar que la fila persiste
count=$($PSQL -c "SELECT COUNT(*) FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';")

# Limpiar fila de prueba
$PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || true

echo "  Filas encontradas tras reinicio: ${count}"

if [[ "$count" -ge 1 ]]; then
  echo "STATUS: PASS"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - La fila no persiste tras reinicio"
exit 1
