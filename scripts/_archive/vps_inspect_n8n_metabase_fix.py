"""Inspeccion READ-ONLY para preparar fixes de n8n encryption key y metabase auth.

NO modifica nada. Solo lee:
 - docker-compose.yml + override + .env del stack postgres_dashboard
 - volumen persistido de n8n (archivo config con encryptionKey)
 - estado de roles en Postgres (sin ALTER, solo \\du + intento de login con
   la password del compose para verificar mismatch)

El `docker compose up --build -d` que esta corriendo no se toca.
"""
import paramiko
import sys
import io

# Forzar utf-8 en stdout para los acentos
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
set +e

STACK_DIR=/etc/easypanel/projects/postgres/dashboard/code

echo '===[1] LS DEL DIRECTORIO DEL STACK ==='
ls -la "$STACK_DIR" 2>&1

echo
echo '===[2] DOCKER-COMPOSE.YML (servicios n8n + metabase, env relevante) ==='
if [ -f "$STACK_DIR/docker-compose.yml" ]; then
  grep -nE 'N8N_ENCRYPTION_KEY|MB_DB_USER|MB_DB_PASS|MB_DB_DBNAME|MB_DB_HOST|MB_DB_PORT|MB_DB_TYPE|n8n_data|metabase_data|/home/node/.n8n|/metabase-data' "$STACK_DIR/docker-compose.yml" 2>&1
else
  echo "NO EXISTE $STACK_DIR/docker-compose.yml"
fi

echo
echo '===[3] DOCKER-COMPOSE.OVERRIDE.YML (si existe) ==='
if [ -f "$STACK_DIR/docker-compose.override.yml" ]; then
  cat "$STACK_DIR/docker-compose.override.yml" 2>&1
else
  echo "NO existe docker-compose.override.yml"
fi

echo
echo '===[4] ARCHIVOS .env EN EL STACK ==='
ls -la "$STACK_DIR"/.env* 2>&1
echo '--- contenido de .env (filtrado a las claves criticas) ---'
if [ -f "$STACK_DIR/.env" ]; then
  grep -E '^(N8N_ENCRYPTION_KEY|MB_DB_USER|MB_DB_PASS|MB_DB_DBNAME|DB_POSTGRESDB_PASSWORD|DB_POSTGRESDB_USER|POSTGRES_PASSWORD|POSTGRES_USER|POSTGRES_DB)=' "$STACK_DIR/.env" 2>&1
else
  echo "NO existe $STACK_DIR/.env"
fi

echo
echo '===[5] VOLUMENES DOCKER (filtrando n8n y metabase) ==='
docker volume ls 2>&1 | grep -iE 'n8n|metabase|postgres_dashboard'

echo
echo '===[6] INSPECT DE VOLUMEN N8N (mountpoint) ==='
for v in $(docker volume ls --format '{{.Name}}' | grep -iE 'n8n'); do
  echo "--- volumen: $v ---"
  docker volume inspect "$v" --format '{{.Name}} -> {{.Mountpoint}}' 2>&1
done

echo
echo '===[7] CONTENIDO DE CADA VOLUMEN N8N (ver si tiene `config`) ==='
for v in $(docker volume ls --format '{{.Name}}' | grep -iE 'n8n'); do
  MP=$(docker volume inspect "$v" --format '{{.Mountpoint}}' 2>/dev/null)
  echo "--- $v ($MP) ---"
  ls -la "$MP" 2>&1 | head -n 30
done

echo
echo '===[8] LEER ARCHIVO config DE n8n (encryptionKey) ==='
for v in $(docker volume ls --format '{{.Name}}' | grep -iE 'n8n'); do
  MP=$(docker volume inspect "$v" --format '{{.Mountpoint}}' 2>/dev/null)
  CFG="$MP/config"
  if [ -f "$CFG" ]; then
    echo "--- archivo: $CFG ---"
    cat "$CFG" 2>&1
    echo
    echo "--- SHA256 truncado de la encryptionKey (para reporte seguro) ---"
    KEY=$(python3 -c "import json,sys; d=json.load(open('$CFG')); print(d.get('encryptionKey',''))" 2>/dev/null)
    if [ -n "$KEY" ]; then
      echo "key_length=${#KEY}"
      echo -n "$KEY" | sha256sum | awk '{print "key_sha256_full="$1}'
      echo -n "$KEY" | sha256sum | awk '{print "key_sha256_short="substr($1,1,8)"..."substr($1,57,8)}'
      echo "key_first4=$(echo -n "$KEY" | cut -c1-4)"
      echo "key_last4=$(echo -n "$KEY" | rev | cut -c1-4 | rev)"
    fi
  else
    echo "NO existe $CFG"
  fi
done

echo
echo '===[9] N8N_ENCRYPTION_KEY EN EL .env (huella sha256 para comparar) ==='
if [ -f "$STACK_DIR/.env" ]; then
  ENV_KEY=$(grep -E '^N8N_ENCRYPTION_KEY=' "$STACK_DIR/.env" | head -n1 | sed 's/^N8N_ENCRYPTION_KEY=//' | sed 's/^"//; s/"$//')
  if [ -n "$ENV_KEY" ]; then
    echo "env_key_length=${#ENV_KEY}"
    echo -n "$ENV_KEY" | sha256sum | awk '{print "env_key_sha256_full="$1}'
    echo -n "$ENV_KEY" | sha256sum | awk '{print "env_key_sha256_short="substr($1,1,8)"..."substr($1,57,8)}'
    echo "env_key_first4=$(echo -n "$ENV_KEY" | cut -c1-4)"
    echo "env_key_last4=$(echo -n "$ENV_KEY" | rev | cut -c1-4 | rev)"
  else
    echo "N8N_ENCRYPTION_KEY NO esta seteada en .env"
  fi
fi

echo
echo '===[10] POSTGRES: existe el contenedor del stack? ==='
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -iE 'postgres|dashboard'

echo
echo '===[11] POSTGRES: listar databases ==='
docker exec postgres_dashboard-postgres-1 psql -U postgres -l 2>&1 | head -n 40

echo
echo '===[12] POSTGRES: rol metabase_user ==='
docker exec postgres_dashboard-postgres-1 psql -U postgres -c "\du metabase_user" 2>&1
docker exec postgres_dashboard-postgres-1 psql -U postgres -c "\du n8n_user" 2>&1

echo
echo '===[13] POSTGRES: leer MB_DB_PASS del .env y probar login de metabase_user ==='
if [ -f "$STACK_DIR/.env" ]; then
  MB_USER=$(grep -E '^MB_DB_USER=' "$STACK_DIR/.env" | head -n1 | sed 's/^MB_DB_USER=//' | sed 's/^"//; s/"$//')
  MB_PASS=$(grep -E '^MB_DB_PASS=' "$STACK_DIR/.env" | head -n1 | sed 's/^MB_DB_PASS=//' | sed 's/^"//; s/"$//')
  MB_DBNAME=$(grep -E '^MB_DB_DBNAME=' "$STACK_DIR/.env" | head -n1 | sed 's/^MB_DB_DBNAME=//' | sed 's/^"//; s/"$//')
  MB_USER_EFF=${MB_USER:-metabase_user}
  MB_DBNAME_EFF=${MB_DBNAME:-metabase_app}
  echo "MB_DB_USER (env)=$MB_USER_EFF"
  echo "MB_DB_DBNAME (env)=$MB_DBNAME_EFF"
  echo "MB_DB_PASS (env, masked)=length=${#MB_PASS} first4=$(echo -n "$MB_PASS" | cut -c1-4) sha256_short=$(echo -n "$MB_PASS" | sha256sum | awk '{print substr($1,1,12)}')"
  echo "MB_DB_PASS (env, FULL clear)=$MB_PASS"
  echo
  echo "--- intento de login metabase_user con password del .env ---"
  docker exec -e PGPASSWORD="$MB_PASS" postgres_dashboard-postgres-1 psql -h localhost -U "$MB_USER_EFF" -d "$MB_DBNAME_EFF" -c 'SELECT current_user, now();' 2>&1 | head -n 10
  echo
  echo "--- intento de login metabase_user contra db postgres (fallback) ---"
  docker exec -e PGPASSWORD="$MB_PASS" postgres_dashboard-postgres-1 psql -h localhost -U "$MB_USER_EFF" -d postgres -c 'SELECT 1;' 2>&1 | head -n 5
fi

echo
echo '===[14] POSTGRES: tambien chequear DB_POSTGRESDB_PASSWORD vs n8n_user ==='
if [ -f "$STACK_DIR/.env" ]; then
  N8N_DB_USER=$(grep -E '^DB_POSTGRESDB_USER=' "$STACK_DIR/.env" | head -n1 | sed 's/^DB_POSTGRESDB_USER=//' | sed 's/^"//; s/"$//')
  N8N_DB_PASS=$(grep -E '^DB_POSTGRESDB_PASSWORD=' "$STACK_DIR/.env" | head -n1 | sed 's/^DB_POSTGRESDB_PASSWORD=//' | sed 's/^"//; s/"$//')
  N8N_DB_NAME=$(grep -E '^DB_POSTGRESDB_DATABASE=' "$STACK_DIR/.env" | head -n1 | sed 's/^DB_POSTGRESDB_DATABASE=//' | sed 's/^"//; s/"$//')
  N8N_DB_USER_EFF=${N8N_DB_USER:-n8n_user}
  N8N_DB_NAME_EFF=${N8N_DB_NAME:-n8n_internal}
  echo "DB_POSTGRESDB_USER=$N8N_DB_USER_EFF"
  echo "DB_POSTGRESDB_DATABASE=$N8N_DB_NAME_EFF"
  echo "DB_POSTGRESDB_PASSWORD (env, masked)=length=${#N8N_DB_PASS} first4=$(echo -n "$N8N_DB_PASS" | cut -c1-4)"
  echo "--- intento de login n8n_user con password del .env ---"
  docker exec -e PGPASSWORD="$N8N_DB_PASS" postgres_dashboard-postgres-1 psql -h localhost -U "$N8N_DB_USER_EFF" -d "$N8N_DB_NAME_EFF" -c 'SELECT current_user;' 2>&1 | head -n 5
fi

echo
echo '===[15] STATE DE LOS CONTENEDORES n8n/metabase (deberian estar ausentes o pulling) ==='
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' 2>&1 | grep -iE 'n8n|metabase|dashboard' | head -n 30

echo
echo '===[16] OPCIONAL: ver si el up --build sigue corriendo ==='
ps -eo pid,etime,cmd | grep -E 'docker.*compose|docker compose' | grep -v grep | head -n 10

echo
echo '===[17] FECHA ==='
date
"""


def main() -> int:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(HOST, username=USER, password=PASS, timeout=20)
    except Exception as e:
        print(f"[ERROR] conexion SSH fallo: {e}", file=sys.stderr)
        return 1

    try:
        _, out, err = client.exec_command(DIAG, timeout=120)
        stdout = out.read().decode(errors="replace")
        stderr = err.read().decode(errors="replace")
        print(stdout)
        if stderr.strip():
            print("---[STDERR]---", file=sys.stderr)
            print(stderr, file=sys.stderr)
    finally:
        client.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
