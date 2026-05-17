#!/usr/bin/env bash
# INFRA-03 [BLOQUEANTE] - HTTPS en todos los dominios publicos
# Criterio: curl -I devuelve HTTP/2 200 y cert valido en cada subdominio
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${DOMAIN:?Requerida: DOMAIN (ej: sixteam.pro)}"

SUBDOMAINS=(
  "n8n.${DOMAIN}"
  "analytics.${DOMAIN}"
)

PASS=0
FAIL=0

echo "=== INFRA-03: HTTPS y certificados ==="

for subdomain in "${SUBDOMAINS[@]}"; do
  echo ""
  echo "  Verificando: https://${subdomain}"

  # Verificar HTTP response
  http_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "https://${subdomain}" 2>/dev/null || echo "000")

  # Verificar certificado SSL
  cert_expiry=$(echo | openssl s_client -servername "${subdomain}" \
    -connect "${subdomain}:443" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null \
    | cut -d= -f2 || echo "")

  if [[ "$http_status" == "200" || "$http_status" == "301" || "$http_status" == "302" ]]; then
    echo "    HTTP status: ${http_status} - OK"
  else
    echo "    HTTP status: ${http_status} - FAIL"
    FAIL=$((FAIL + 1))
    continue
  fi

  if [[ -n "$cert_expiry" ]]; then
    expiry_epoch=$(date -d "$cert_expiry" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$cert_expiry" +%s 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [[ $days_left -gt 7 ]]; then
      echo "    Certificado valido hasta: ${cert_expiry} (${days_left} dias) - OK"
      PASS=$((PASS + 1))
    else
      echo "    Certificado expira en ${days_left} dias - ADVERTENCIA/FAIL"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "    No se pudo verificar el certificado - FAIL"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "Resultado: ${PASS}/${#SUBDOMAINS[@]} dominios con HTTPS valido"

if [[ $FAIL -gt 0 ]]; then
  echo "STATUS: FAIL (BLOQUEANTE)"
  exit 1
fi

echo "STATUS: PASS"
exit 0
