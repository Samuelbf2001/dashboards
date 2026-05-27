"""READ-ONLY: descubrir como EasyPanel inyecta secretos al stack postgres_dashboard.

El .env del disco tiene `CAMBIAR_POR_SECRET_MANAGER`, pero los contenedores
viejos pueden haber tenido valores reales inyectados por EasyPanel via
`docker compose up` con env overrides. Verificamos:
 1. Si hay contenedores recientemente recreados con env reales.
 2. Si EasyPanel tiene un panel db con los secrets persistidos.
 3. Si el contenedor que ahora se esta creando (postgres_dashboard-n8n-1
    o metabase-1) ya existe con `docker inspect`.
 4. Los logs del docker compose up que estuvo corriendo (journalctl easypanel).
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

echo '===[1] EASYPANEL: stack postgres_dashboard, listar archivos relevantes ==='
ls -la /etc/easypanel/projects/postgres/dashboard/ 2>&1
echo
ls -la /etc/easypanel/projects/postgres/ 2>&1 | head -n 20

echo
echo '===[2] EASYPANEL DB: buscar archivos de config global ==='
ls -la /etc/easypanel/ 2>&1 | head -n 30

echo
echo '===[3] BUSCAR EL VERDADERO N8N_ENCRYPTION_KEY EN EL FILESYSTEM ==='
# Buscamos en metadata de EasyPanel donde guarda los secretos del servicio
grep -rlE 'N8N_ENCRYPTION_KEY' /etc/easypanel/ 2>/dev/null | head -n 10
echo '---'
grep -rlE 'MB_DB_PASS' /etc/easypanel/ 2>/dev/null | head -n 10

echo
echo '===[4] CONTENEDORES n8n / metabase recientes (incluido recien creados) ==='
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Image}}' 2>&1 | grep -iE 'postgres_dashboard|^NAMES' | head -n 20

echo
echo '===[5] PROBAR LEER ENV DE UN CONTENEDOR n8n/metabase del stack actual (si existe) ==='
for c in postgres_dashboard-n8n-1 postgres_dashboard-metabase-1; do
  echo "--- $c ---"
  docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>&1 | grep -E '^(N8N_ENCRYPTION_KEY|MB_DB_PASS|MB_DB_USER|MB_DB_DBNAME|DB_POSTGRESDB_PASSWORD|DB_POSTGRESDB_USER|POSTGRES_PASSWORD)=' | sed 's/=\(.\{4\}\).*$/=\1...[REDACTED]/'
done

echo
echo '===[6] LOGS DE EASYPANEL (servicio systemd) ULTIMOS 60s para ver si hubo up reciente ==='
journalctl -u easypanel.service -n 80 --no-pager 2>&1 | tail -n 80

echo
echo '===[7] BUSCAR EL ARCHIVO DE EasyPanel DB (donde guarda las env secretas) ==='
find /etc/easypanel -maxdepth 4 -type f \( -name '*.json' -o -name '*.db' -o -name '*.sqlite' -o -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | head -n 40

echo
echo '===[8] LEER EL JSON DEL SERVICIO EN EASYPANEL (si existe) ==='
# EasyPanel suele guardar en /etc/easypanel/db.json o similar
for f in /etc/easypanel/db.json /etc/easypanel/projects.json /etc/easypanel/data.json; do
  if [ -f "$f" ]; then
    echo "--- $f (tail 80) ---"
    head -c 2000 "$f" 2>&1
    echo
  fi
done

echo
echo '===[9] CONTENEDOR easypanel-controller (env, donde se guardan secretos) ==='
docker ps -a --format '{{.Names}}' | grep -iE 'easypanel' | head -n 5

echo
echo '===[10] BUSCAR la key real 663a1244... en /etc/easypanel (sanity check) ==='
# Si EasyPanel tiene la key real, deberia aparecer en algun archivo
grep -rlE '663a1244' /etc/easypanel/ 2>/dev/null | head -n 10

echo
echo '===[11] BUSCAR strings random de 32 chars en archivos de EasyPanel del stack postgres_dashboard ==='
find /etc/easypanel -path '*postgres*' -type f 2>/dev/null | head -n 30

echo
echo '===[12] Estado del docker compose up (sigue corriendo?) ==='
ps -eo pid,etime,user,cmd | grep -iE 'docker.*compose|compose.*up|docker-compose' | grep -v grep | head -n 10

echo
echo '===[13] EVENTOS DOCKER ULTIMOS 5 MINUTOS (create/start de n8n/metabase) ==='
docker events --since 5m --until 0s --filter 'event=create' --filter 'event=start' --filter 'event=destroy' 2>&1 | head -n 40
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
