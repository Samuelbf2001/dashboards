#!/usr/bin/env bash
# PERF-05 [BLOQUEANTE] - Uso de RAM total del stack < 3GB
# Criterio: docker stats suma RAM de los 5 containers, valida < 3072 MB
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${MAX_RAM_MB:=3072}"

CONTAINERS=("postgres" "n8n" "metabase" "traefik" "uptime-kuma")

echo "=== PERF-05: RAM usage ==="

TOTAL_MB=0
FAIL=0

for name in "${CONTAINERS[@]}"; do
  # docker stats devuelve en formato "123.4MiB" o "1.2GiB"
  ram_raw=$(docker stats --no-stream --format "{{.MemUsage}}" \
    $(docker ps --filter "name=${name}" --format "{{.Names}}" | head -1) \
    2>/dev/null | awk '{print $1}' | head -1)

  if [[ -z "$ram_raw" ]]; then
    echo "  ${name}: no encontrado (0 MB)"
    continue
  fi

  # Convertir a MB
  if [[ "$ram_raw" == *"GiB"* ]]; then
    val=$(echo "$ram_raw" | sed 's/GiB//')
    ram_mb=$(echo "scale=0; $val * 1024 / 1" | bc)
  elif [[ "$ram_raw" == *"MiB"* ]]; then
    ram_mb=$(echo "$ram_raw" | sed 's/MiB//' | xargs printf "%.0f")
  elif [[ "$ram_raw" == *"kB"* || "$ram_raw" == *"KiB"* ]]; then
    val=$(echo "$ram_raw" | sed 's/[kK][Bi][Bi]//')
    ram_mb=$(echo "scale=0; $val / 1024 / 1" | bc)
  else
    ram_mb=0
  fi

  echo "  ${name}: ${ram_raw} (~${ram_mb} MB)"
  TOTAL_MB=$((TOTAL_MB + ram_mb))
done

echo ""
echo "  RAM total: ${TOTAL_MB} MB (limite: ${MAX_RAM_MB} MB)"

if [[ $TOTAL_MB -le $MAX_RAM_MB ]]; then
  echo "STATUS: PASS - RAM total ${TOTAL_MB}MB dentro del limite"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - RAM total ${TOTAL_MB}MB supera limite de ${MAX_RAM_MB}MB"
echo "  Considerar: escalar VPS verticalmente o reducir heap de Metabase/n8n"
exit 1
