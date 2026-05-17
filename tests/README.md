# Test Suite - GHL Analytics Platform

Suite de tests ejecutables que validan los criterios de aceptacion del spec v1.0.0.

## Prerrequisitos

- bash 4+
- curl
- jq
- openssl
- docker
- psql (postgresql-client)
- bc

Instalar en Ubuntu/Debian:
```bash
apt-get install -y curl jq openssl docker.io postgresql-client bc
```

## Variables de entorno requeridas

Copiar `.env.example` a `.env` y completar:

```bash
cp ../.env.example ../.env
# Editar .env con los valores reales
```

### Variables minimas para ejecutar la suite completa

```bash
# PostgreSQL
POSTGRES_HOST=localhost          # o IP del VPS
POSTGRES_PORT=5432
POSTGRES_DB=ghl_analytics
POSTGRES_USER=sixteam_admin
POSTGRES_PASSWORD=xxx

# n8n
N8N_HOST=n8n.tudominio.com
WEBHOOK_SECRET=xxx

# Metabase
MB_SITE_URL=https://analytics.tudominio.com
METABASE_ADMIN_USER=admin@sixteam.pro
METABASE_ADMIN_PASSWORD=xxx

# Tests de seguridad RLS
CLIENT_A_ROLE=client_loc_abc123
CLIENT_A_PASSWORD=xxx
CLIENT_B_LOCATION_ID=loc_xyz789

# Tests de embedding y clientes
METABASE_CLIENT_USER=cliente@empresa.com
METABASE_CLIENT_PASSWORD=xxx
CLIENT_LOCATION_ID=loc_abc123
OTHER_LOCATION_ID=loc_xyz789

# Meta
META_VERIFY_TOKEN=xxx

# Sistema
DOMAIN=tudominio.com
TEST_LOCATION_ID=loc_test_etl
```

### Variables adicionales para tests especificos

```bash
# PERF-02: ajustar el tamano del sample
SAMPLE_SIZE=20       # default: 20 (usar 100 para prueba completa en produccion)

# MB-04, MB-06: IDs de cards en Metabase (opcional, para comparacion exacta)
TEST_PIPELINE_CARD_ID=   # ID del card "Tasa de conversion" en Metabase
MB_FIRST_REPLY_CARD_ID=  # ID del card "Avg First Reply Time"
```

## Dataset seed minimo

Antes de correr los tests ETL y MB, la BD debe tener datos de al menos 2 clientes distintos:

```sql
-- Ejecutar en la BD ghl_analytics como sixteam_admin
-- Insertar datos de 2 location_id distintos para SEC-02 y MB-07

INSERT INTO dim_contacts (contact_id, location_id, email, first_name, last_name, valid_from, is_current)
VALUES
  ('seed_c001', 'loc_cliente_a', 'test_a@test.com', 'Test', 'A', NOW(), TRUE),
  ('seed_c002', 'loc_cliente_b', 'test_b@test.com', 'Test', 'B', NOW(), TRUE);

INSERT INTO dim_opportunities (opportunity_id, contact_id, location_id, pipeline_id, status, monetary_value, valid_from, is_current)
VALUES
  ('seed_o001', 'seed_c001', 'loc_cliente_a', 'pipe_001', 'won',  1500000, NOW(), TRUE),
  ('seed_o002', 'seed_c001', 'loc_cliente_a', 'pipe_001', 'lost', 800000,  NOW(), TRUE),
  ('seed_o003', 'seed_c002', 'loc_cliente_b', 'pipe_002', 'open', 2000000, NOW(), TRUE);

-- Refrescar la vista materializada despues del seed
REFRESH MATERIALIZED VIEW mv_unified_attribution;
```

## Ejecucion

### Todos los tests
```bash
cd tests/
./run_all.sh
```

### Por categoria
```bash
./run_all.sh infra
./run_all.sh security
./run_all.sh etl
./run_all.sh metabase
./run_all.sh perf
```

### Multiples categorias
```bash
./run_all.sh infra sec
```

### Solo tests BLOQUEANTES
```bash
./run_all.sh --skip-non-blocking
```

### Test individual
```bash
bash tests/etl/etl_01_webhook_upsert.sh
```

## Clasificacion de tests

| Categoria | Total | Bloqueantes |
|---|---|---|
| INFRA | 5 | 5 |
| SEC | 8 | 8 |
| ETL | 10 | 10 |
| MB | 4 | 4 |
| PERF | 3 | 3 |
| **Total** | **30** | **30** |

Todos los tests implementados son BLOQUEANTES segun el spec.

## Exit codes

- `0`: Todos los tests pasaron (o todos los BLOQUEANTES pasaron)
- `1`: Al menos 1 test BLOQUEANTE fallo

## Tests que requieren intervencion manual

Los siguientes tests no son completamente automatizables sin entorno live:

- **ETL-04**: Requiere que WF-07 haya corrido al menos una vez previamente
- **ETL-07**: WF-11 es cron cada 30 min; la correlacion puede no ocurrir en el window del test
- **MB-01**: Requiere que los 6 dashboards hayan sido recreados manualmente en Metabase
- **MB-02**: Requiere usuario cliente real creado en Metabase con grupo configurado
- **PERF-02**: Con SAMPLE_SIZE=100 tarda ~25 minutos; usar SAMPLE_SIZE=20 para CI rapido

## Troubleshooting

### "No se pudo autenticar en Metabase"
Verificar `METABASE_ADMIN_USER` y `METABASE_ADMIN_PASSWORD`. Asegurar que Metabase este corriendo.

### "Webhook no llega a PostgreSQL"
1. Verificar que n8n este corriendo: `docker ps | grep n8n`
2. Verificar WEBHOOK_SECRET coincide con el configurado en GHL
3. Revisar logs: `docker logs n8n --tail 50`

### "RLS falla - cliente ve datos de otro"
1. Verificar que el rol tiene RLS policy: `\dp dim_contacts` en psql
2. Verificar que `FORCE ROW LEVEL SECURITY` esta aplicado
3. Ver docs/TROUBLESHOOTING.md seccion "cliente ve datos de otro cliente"
