#!/usr/bin/env bash
# =============================================================================
# GHL Analytics Platform — Backup diario de PostgreSQL
# Ejecuta pg_dump en formato custom (-Fc) y rota backups de 7 días.
# Se monta dentro del contenedor postgres o en un contenedor auxiliar.
# =============================================================================
set -euo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────
BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${POSTGRES_DB:?Variable POSTGRES_DB no definida}"
DB_USER="${POSTGRES_USER:?Variable POSTGRES_USER no definida}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
DATE=$(date +%F)
BACKUP_FILE="${BACKUP_DIR}/${DATE}.dump"

# ─── Exportar contraseña para pg_dump (evita prompt interactivo) ──────────────
export PGPASSWORD="${POSTGRES_PASSWORD:?Variable POSTGRES_PASSWORD no definida}"

# ─── Crear directorio si no existe ───────────────────────────────────────────
mkdir -p "${BACKUP_DIR}"

echo "[$(date -Iseconds)] Iniciando backup de ${DB_NAME} → ${BACKUP_FILE}"

# ─── Ejecutar pg_dump en formato custom comprimido ───────────────────────────
# -Fc: formato custom (comprimido, restaurable con pg_restore)
# --no-password: usa PGPASSWORD del entorno
pg_dump \
  -h "${DB_HOST}" \
  -p "${DB_PORT}" \
  -U "${DB_USER}" \
  -Fc \
  --no-password \
  --verbose \
  "${DB_NAME}" \
  > "${BACKUP_FILE}"

BACKUP_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
echo "[$(date -Iseconds)] Backup completado. Tamaño: ${BACKUP_SIZE} → ${BACKUP_FILE}"

# ─── Rotación: eliminar backups más antiguos que RETENTION_DAYS ───────────────
echo "[$(date -Iseconds)] Rotando backups anteriores a ${RETENTION_DAYS} días..."
find "${BACKUP_DIR}" -name "*.dump" -mtime "+${RETENTION_DAYS}" -delete
REMAINING=$(find "${BACKUP_DIR}" -name "*.dump" | wc -l)
echo "[$(date -Iseconds)] Backups retenidos: ${REMAINING}"

# ─── Limpiar variable de entorno sensible ─────────────────────────────────────
unset PGPASSWORD

echo "[$(date -Iseconds)] Proceso de backup finalizado correctamente."

# =============================================================================
# RESTORE (referencia — ejecutar manualmente cuando se necesite):
#
#   pg_restore \
#     -h <HOST> -p 5432 -U <USER> \
#     -d ghl_analytics \
#     --no-owner --role=ghl_user \
#     /backups/2026-05-16.dump
#
# Para listar el contenido del dump sin restaurar:
#   pg_restore --list /backups/2026-05-16.dump
# =============================================================================
