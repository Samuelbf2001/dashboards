#!/usr/bin/env bash
# PERF-01 [BLOQUEANTE] - Query principal del Dashboard Pipeline en < 3 segundos
# Criterio: query de funnel por etapa con 50,000 oportunidades completa en < 3s
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"
: "${MAX_SECONDS:=3}"

echo "=== PERF-01: Pipeline query performance ==="

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

# Verificar numero de oportunidades en BD
opp_count=$($PSQL -c "SELECT COUNT(*) FROM dim_opportunities WHERE is_current = TRUE;" 2>/dev/null || echo 0)
echo "  Oportunidades actuales en BD: ${opp_count}"

# Ejecutar la query principal del pipeline dashboard y medir tiempo
start=$(date +%s%3N)

result=$($PSQL -c "
  SELECT
    o.stage_name,
    p.stage_order,
    COUNT(DISTINCT o.opportunity_id) AS total_opps,
    COALESCE(SUM(o.monetary_value), 0) AS valor_en_etapa
  FROM dim_opportunities o
  JOIN dim_pipelines p
    ON p.pipeline_id = o.pipeline_id
    AND p.stage_id = o.pipeline_stage_id
  WHERE o.is_current = TRUE
    AND o.status = 'open'
  GROUP BY o.stage_name, p.stage_order
  ORDER BY p.stage_order ASC;
" 2>/dev/null)

end=$(date +%s%3N)
elapsed_ms=$((end - start))
elapsed_s=$(echo "scale=2; $elapsed_ms / 1000" | bc)

echo "  Tiempo de ejecucion: ${elapsed_ms}ms (${elapsed_s}s)"
echo "  Filas devueltas: $(echo "$result" | wc -l)"

if (( elapsed_ms <= (MAX_SECONDS * 1000) )); then
  echo "STATUS: PASS - Query completo en ${elapsed_s}s (limite: ${MAX_SECONDS}s)"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Query tardo ${elapsed_s}s (limite: ${MAX_SECONDS}s)"
echo "  Verificar indices: idx_opps_location, idx_opps_status, idx_pipelines_pipeline_id"
exit 1
