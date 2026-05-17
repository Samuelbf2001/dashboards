#!/usr/bin/env bash
# Orquestador de tests - GHL Analytics Platform
# Corre todos los tests por categoria: INFRA -> SEC -> ETL -> MB -> PERF
# Tests BLOQUEANTES: los marcados como tal en el spec. Exit code != 0 si alguno falla.
#
# Uso:
#   ./run_all.sh                    # todos los tests
#   ./run_all.sh infra              # solo categoria infra
#   ./run_all.sh sec etl            # sec y etl
#   ./run_all.sh --skip-non-blocking  # solo bloqueantes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATEGORIES=("infra" "security" "etl" "metabase" "perf")
SKIP_NON_BLOCKING=false
SELECTED_CATS=()

# Parsear argumentos
for arg in "$@"; do
  case "$arg" in
    --skip-non-blocking) SKIP_NON_BLOCKING=true ;;
    infra|security|sec|etl|metabase|mb|perf) SELECTED_CATS+=("$arg") ;;
    *) echo "Argumento desconocido: $arg"; exit 1 ;;
  esac
done

# Si se seleccionaron categorias, usar solo esas
if [[ ${#SELECTED_CATS[@]} -gt 0 ]]; then
  CATEGORIES=("${SELECTED_CATS[@]}")
fi

# Tests BLOQUEANTES segun el spec (seccion 9 + Implementation Plan seccion 7)
declare -A BLOCKING_TESTS
BLOCKING_TESTS=(
  ["infra_01_containers_healthy.sh"]="INFRA-01"
  ["infra_02_postgres_persistence.sh"]="INFRA-02"
  ["infra_03_https_certs.sh"]="INFRA-03"
  ["infra_04_no_hardcoded_secrets.sh"]="INFRA-04"
  ["infra_05_backup_works.sh"]="INFRA-05"
  ["sec_01_rls_isolation.sh"]="SEC-01"
  ["sec_02_superadmin_sees_all.sh"]="SEC-02"
  ["sec_03_cors_rejects_unauthorized.sh"]="SEC-03"
  ["sec_04_rate_limit.sh"]="SEC-04"
  ["sec_05_hmac_validation.sh"]="SEC-05"
  ["sec_06_sql_injection.sh"]="SEC-06"
  ["sec_07_metabase_no_anon.sh"]="SEC-07"
  ["sec_09_n8n_auth.sh"]="SEC-09"
  ["sec_10_meta_verify.sh"]="SEC-10"
  ["etl_01_webhook_upsert.sh"]="ETL-01"
  ["etl_02_opp_history.sh"]="ETL-02"
  ["etl_03_no_duplicates.sh"]="ETL-03"
  ["etl_04_cursor_increment.sh"]="ETL-04"
  ["etl_05_malformed_payload.sh"]="ETL-05"
  ["etl_06_ctwa_capture.sh"]="ETL-06"
  ["etl_07_ctwa_correlation.sh"]="ETL-07"
  ["etl_08_utm_extraction.sh"]="ETL-08"
  ["etl_09_email_lowercase.sh"]="ETL-09"
  ["etl_10_phone_e164.sh"]="ETL-10"
  ["mb_01_dashboards_load.sh"]="MB-01"
  ["mb_02_rls_in_dashboard.sh"]="MB-02"
  ["mb_04_conversion_rate_calc.sh"]="MB-04"
  ["mb_06_first_reply_calc.sh"]="MB-06"
  ["mb_09_column_arithmetic.sh"]="MB-09"
  ["perf_01_pipeline_query.sh"]="PERF-01"
  ["perf_02_webhook_latency.sh"]="PERF-02"
  ["perf_05_ram_usage.sh"]="PERF-05"
)

# Contadores
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
BLOCKING_FAILED=0
NON_BLOCKING_FAILED=0

FAILED_TESTS=()
START_TIME=$(date +%s)

# Cargar .env si existe
if [[ -f "${SCRIPT_DIR}/../.env" ]]; then
  export $(grep -v '^#' "${SCRIPT_DIR}/../.env" | xargs) 2>/dev/null || true
fi

echo "=================================================="
echo "  GHL Analytics Platform - Test Suite"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="

# Funcion para correr un test
run_test() {
  local script="$1"
  local category="$2"
  local script_name
  script_name=$(basename "$script")
  local test_id="${BLOCKING_TESTS[$script_name]:-NON-BLOCKING}"
  local is_blocking=false

  [[ -n "${BLOCKING_TESTS[$script_name]:-}" ]] && is_blocking=true

  if [[ "$SKIP_NON_BLOCKING" == "true" && "$is_blocking" == "false" ]]; then
    return
  fi

  TOTAL=$((TOTAL + 1))

  local label
  [[ "$is_blocking" == "true" ]] && label="[BLOQUEANTE]" || label="[no-bloqueante]"

  printf "\n  %-45s %s\n" "${script_name}" "${label}"

  if bash "$script" > /tmp/test_output.txt 2>&1; then
    PASSED=$((PASSED + 1))
    echo "  -> PASS"
  else
    local exit_code=$?
    last_line=$(tail -1 /tmp/test_output.txt)
    echo "  -> FAIL: ${last_line}"
    FAILED=$((FAILED + 1))
    FAILED_TESTS+=("${test_id:-$script_name}")

    if [[ "$is_blocking" == "true" ]]; then
      BLOCKING_FAILED=$((BLOCKING_FAILED + 1))
    else
      NON_BLOCKING_FAILED=$((NON_BLOCKING_FAILED + 1))
    fi
  fi
}

# Ejecutar por categoria
for cat in "${CATEGORIES[@]}"; do
  # Normalizar nombre de categoria
  case "$cat" in
    sec) cat="security" ;;
    mb) cat="metabase" ;;
  esac

  cat_dir="${SCRIPT_DIR}/${cat}"

  if [[ ! -d "$cat_dir" ]]; then
    echo ""
    echo "  [SKIP] Categoria '${cat}' no encontrada en ${cat_dir}"
    continue
  fi

  echo ""
  echo "--- ${cat^^} ---"

  scripts=("${cat_dir}"/*.sh)
  if [[ "${scripts[0]}" == "${cat_dir}/*.sh" ]]; then
    echo "  Sin scripts en ${cat_dir}"
    continue
  fi

  for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
      chmod +x "$script" 2>/dev/null || true
      run_test "$script" "$cat"
    fi
  done
done

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "=================================================="
echo "  RESUMEN DE TESTS"
echo "=================================================="
echo "  Total:          ${TOTAL}"
echo "  Pasados:        ${PASSED}"
echo "  Fallidos:       ${FAILED}"
echo "  Bloqueantes fallidos: ${BLOCKING_FAILED}"
echo "  No-bloqueantes fallidos: ${NON_BLOCKING_FAILED}"
echo "  Tiempo total:   ${ELAPSED}s"

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
  echo ""
  echo "  Tests fallidos:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "    - ${t}"
  done
fi

echo ""
if [[ $BLOCKING_FAILED -gt 0 ]]; then
  echo "  RESULTADO: NO LISTO PARA PRODUCCION"
  echo "  ${BLOCKING_FAILED} test(s) BLOQUEANTE(S) fallaron."
  echo "=================================================="
  exit 1
fi

if [[ $NON_BLOCKING_FAILED -gt 0 ]]; then
  echo "  RESULTADO: LISTO PARA PRODUCCION (con advertencias)"
  echo "  ${NON_BLOCKING_FAILED} test(s) no-bloqueante(s) fallaron."
  echo "=================================================="
  exit 0
fi

echo "  RESULTADO: LISTO PARA PRODUCCION"
echo "  Todos los tests pasaron."
echo "=================================================="
exit 0
