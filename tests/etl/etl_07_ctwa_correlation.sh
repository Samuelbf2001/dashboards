#!/usr/bin/env bash
# ETL-07 [BLOQUEANTE] - WF-11 correlaciona ctwa_clid con contact_id
# Criterio: tras crear contacto en GHL, fact_ctwa_clicks.contact_id se rellena
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${WEBHOOK_SECRET:?Requerida: WEBHOOK_SECRET}"
: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"
: "${TEST_LOCATION_ID:=loc_test_etl}"

TEST_PHONE="+573008887766"
TEST_CTWA_CLID="test_corr_clid_etl07_$(date +%s)"
TEST_CONTACT_ID="test_corr_contact_etl07_$(date +%s)"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

echo "=== ETL-07: CTWA correlation ==="
echo "  ctwa_clid: ${TEST_CTWA_CLID}"
echo "  phone: ${TEST_PHONE}"
echo "  contact_id: ${TEST_CONTACT_ID}"

# Paso 1: Insertar click CTWA directamente (sin contact_id aun)
$PSQL -c "
  INSERT INTO fact_ctwa_clicks (ctwa_clid, phone, ad_id, campaign_id, campaign_name, clicked_at)
  VALUES ('${TEST_CTWA_CLID}', '${TEST_PHONE}', 'ad_test', 'campaign_test', 'Campana ETL07', NOW())
  ON CONFLICT (ctwa_clid) DO NOTHING;
"
echo "  Click CTWA insertado (contact_id=NULL)"

# Paso 2: Crear contacto con el mismo phone via webhook GHL
CONTACT_PAYLOAD=$(cat <<EOF
{
  "type": "ContactCreate",
  "locationId": "${TEST_LOCATION_ID}",
  "id": "${TEST_CONTACT_ID}",
  "phone": "${TEST_PHONE}",
  "firstName": "CTWA",
  "lastName": "Corr Test"
}
EOF
)
SIGNATURE=$(echo -n "${CONTACT_PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

http_code=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: ${SIGNATURE}" \
  -d "${CONTACT_PAYLOAD}" \
  --max-time 10 \
  "https://${N8N_HOST}/ghl/contacts" 2>/dev/null || echo "000")
echo "  Contacto creado via webhook: HTTP ${http_code}"

# Paso 3: Esperar a que WF-11 correlacione (puede tardar hasta 30 min si es solo cron)
# Para test inmediato, WF-11 deberia dispararse por webhook o ejecutarse manualmente.
echo "  Esperando 30s para correlacion automatica..."
sleep 30

correlated=$($PSQL -c "
  SELECT contact_id
  FROM fact_ctwa_clicks
  WHERE ctwa_clid = '${TEST_CTWA_CLID}'
  LIMIT 1;
" 2>/dev/null || echo "")

echo "  contact_id en fact_ctwa_clicks: ${correlated}"

# Limpiar
$PSQL -c "DELETE FROM fact_ctwa_clicks WHERE ctwa_clid = '${TEST_CTWA_CLID}';" 2>/dev/null || true
$PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || true

if [[ -n "$correlated" && "$correlated" != "" && "$correlated" != "NULL" ]]; then
  echo "STATUS: PASS - contact_id correlacionado: ${correlated}"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - WF-11 no correlaciono ctwa_clid con contact_id en 30s"
echo "  Nota: WF-11 es cron cada 30 min. Si el cron no corrio durante el test, este fallo es esperado."
echo "  Para prueba manual: ejecutar WF-11 desde n8n UI y re-correr este test."
exit 1
