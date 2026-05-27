"""READ-ONLY: ver env vars del portal (que SI tiene credenciales reales)
y comparar con el .env del disco. Confirmar que la unica fuente de la
key real n8n es el archivo persistido en el volumen.
"""
import paramiko
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
set +e

echo '===[1] DOCKER PS -A: contenedores del stack postgres_dashboard (todos los estados) ==='
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}' 2>&1 | grep -iE 'postgres_dashboard|NAMES'

echo
echo '===[2] ENV REAL DEL POSTGRES DEL STACK (para conocer POSTGRES_PASSWORD y MB_DB_PASS reales) ==='
# El contenedor postgres lleva 22 horas, asi que tiene los env REALES que se le pasaron
docker inspect postgres_dashboard-postgres-1 --format '{{range .Config.Env}}{{println .}}{{end}}' 2>&1 | grep -E '^(POSTGRES_|DB_POSTGRESDB_|MB_DB_|N8N_)' | head -n 30

echo
echo '===[3] EXISTE portal_data? Hay contenedor portal corriendo (con env real)? ==='
docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep -iE 'portal' | head -n 5
PORTAL=$(docker ps -a --format '{{.Names}}' | grep -iE 'postgres_dashboard.*portal' | head -n1)
if [ -n "$PORTAL" ]; then
  echo "--- env del portal: $PORTAL ---"
  docker inspect "$PORTAL" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>&1 | grep -E '^(POSTGRES_|MB_|PORTAL_|METABASE_)' | head -n 20
fi

echo
echo '===[4] BUSCAR contenedores n8n / metabase del stack postgres_dashboard EN CUALQUIER ESTADO ==='
docker ps -a --no-trunc --format '{{.Names}} | {{.Status}} | {{.CreatedAt}}' 2>&1 | grep -iE 'postgres_dashboard.*(n8n|metabase)' | head -n 10

echo
echo '===[5] VERIFICAR PASSWORD REAL en POSTGRES con el password del .env ==='
# Si el login con CAMBIAR_POR_SECRET_MANAGER funciono, esa ES la password real
# Confirmamos con el ROL sixteam_admin tambien:
docker exec -e PGPASSWORD='CAMBIAR_POR_SECRET_MANAGER' postgres_dashboard-postgres-1 psql -h localhost -U sixteam_admin -d postgres -c 'SELECT current_user;' 2>&1 | head -n 5
echo '--- pg_roles existentes con login ---'
docker exec -e PGPASSWORD='CAMBIAR_POR_SECRET_MANAGER' postgres_dashboard-postgres-1 psql -h localhost -U metabase_user -d postgres -c "SELECT rolname FROM pg_roles WHERE rolcanlogin = true ORDER BY 1;" 2>&1

echo
echo '===[6] EXISTE LA DATABASE metabase_app? (verificar que metabase puede conectarse) ==='
docker exec -e PGPASSWORD='CAMBIAR_POR_SECRET_MANAGER' postgres_dashboard-postgres-1 psql -h localhost -U metabase_user -d metabase_app -c "SELECT count(*) AS tablas FROM information_schema.tables WHERE table_schema='public';" 2>&1 | head -n 10

echo
echo '===[7] VOLUMEN metabase_data: tiene contenido (estaba inicializado)? ==='
ls -la /var/lib/docker/volumes/postgres_dashboard_metabase_data/_data 2>&1 | head -n 20

echo
echo '===[8] HISTORIAL de contenedores eliminados que matchean nuestro stack ==='
# Docker tiene un journalctl con eventos de docker, pero alternativo:
journalctl --since '24 hours ago' --until 'now' 2>/dev/null | grep -iE 'postgres_dashboard-(n8n|metabase)' | tail -n 20

echo
echo '===[9] VERIFICAR si docker compose esta corriendo ahora ==='
ps -eo pid,etime,user,cmd 2>&1 | grep -iE 'docker.*compose|docker-compose' | grep -v grep

echo
echo '===[10] IMAGES n8n / metabase descargadas ==='
docker images 2>&1 | grep -iE 'n8n|metabase|NAMES|REPOSITORY' | head -n 20
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
        _, out, err = client.exec_command(DIAG, timeout=90)
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
