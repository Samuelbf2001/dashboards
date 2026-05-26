#!/usr/bin/env bash
# 15_set_role_passwords.sh — Asigna contraseñas a los roles de la plataforma.
#
# Este script se ejecuta automáticamente en el primer arranque del contenedor
# Postgres (junto con los .sql de db/init/), como parte de
# docker-entrypoint-initdb.d.
#
# Prerequisito: el docker-compose.yml expone DB_POSTGRESDB_PASSWORD y
# MB_DB_PASS en el entorno del contenedor postgres.

set -e

psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" \
     --dbname   "$POSTGRES_DB" <<-EOSQL

  -- n8n_user: usuario que n8n usa para conectar a n8n_internal y ghl_analytics
  ALTER ROLE n8n_user WITH PASSWORD '${DB_POSTGRESDB_PASSWORD}';

  -- n8n_writer: rol de escritura en ghl_analytics (n8n_user lo hereda)
  -- Usa la misma contraseña para simplificar la configuración de credenciales
  ALTER ROLE n8n_writer WITH PASSWORD '${DB_POSTGRESDB_PASSWORD}';

  -- metabase_user: usuario que Metabase usa para conectar
  ALTER ROLE metabase_user WITH PASSWORD '${MB_DB_PASS}';

  -- sixteam_admin: superadmin de la plataforma (usa POSTGRES_PASSWORD)
  ALTER ROLE sixteam_admin WITH PASSWORD '${POSTGRES_PASSWORD}';

EOSQL

echo "✓ Contraseñas de roles asignadas correctamente."
