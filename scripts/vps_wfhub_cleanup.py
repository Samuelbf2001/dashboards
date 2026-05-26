"""TAREA 3b — Limpieza del servicio Swarm fantasma wfhub_evolution-api.

Criterios verificados ANTES de borrar (segun vps_wfhub_inspect.py):
- /etc/easypanel/projects/wfhub NO existe (solo postgres, whatsful, whatsfull)
- Servicio Swarm wfhub_evolution-api con 0/1 replicas, 9 tasks fallidas
- Ningun task en estado Running
- No hay stack docker
- Volumen wfhub_evolution-api_instances existe pero NO se borra (data del usuario)
- Red easypanel-wfhub existe pero NO se borra (no es destructivo, queda sin uso)
- Imagen evoapicloud/evolution-api NO se borra (whatsfull_evoapi la usa)

Acciones (en orden):
1. docker service rm wfhub_evolution-api  -> borra el servicio Y todas sus tasks
2. Si quedan contenedores wfhub colgados -> docker rm por ID
3. Verifica post-limpieza
"""
import paramiko
import sys

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

CLEANUP = r"""
set -e

echo '===[A] UPTIME ANTES ==='
uptime

echo
echo '===[B] ESTADO ANTES ==='
echo '--- service ls wfhub ---'
docker service ls | grep -i wfhub || echo '(ninguno)'
echo '--- ps -a wfhub ---'
docker ps -a --format "{{.ID}} {{.Names}} {{.Status}}" | grep -i wfhub || echo '(ninguno)'

echo
echo '===[1] docker service rm wfhub_evolution-api ==='
docker service rm wfhub_evolution-api
echo 'OK -> servicio borrado'

echo
echo '===[2] VERIFICACION post-service-rm ==='
echo '--- service ls wfhub ---'
docker service ls | grep -i wfhub || echo '(ninguno - OK)'
echo '--- ps -a wfhub ---'
docker ps -a --format "{{.ID}} {{.Names}} {{.Status}}" | grep -i wfhub || echo '(ninguno - OK)'

echo
echo '===[3] BORRAR CONTENEDORES wfhub RESIDUALES (si quedan) ==='
RESIDUAL=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep -i wfhub | awk '{print $1}')
if [ -z "$RESIDUAL" ]; then
  echo '(no quedan contenedores wfhub residuales - OK)'
else
  for cid in $RESIDUAL; do
    echo "--- docker rm $cid ---"
    docker rm "$cid" || echo "fallo borrando $cid"
  done
fi

echo
echo '===[4] VERIFICACION FINAL ==='
echo '--- service ls wfhub ---'
docker service ls | grep -i wfhub || echo '(ninguno - OK)'
echo '--- ps -a wfhub ---'
docker ps -a --format "{{.ID}} {{.Names}} {{.Status}}" | grep -i wfhub || echo '(ninguno - OK)'
echo '--- stack ls wfhub ---'
docker stack ls | grep -i wfhub || echo '(ninguno - OK)'

echo
echo '===[C] UPTIME DESPUES ==='
uptime

echo
echo '===[D] DOCKER STATS (post-limpieza) ==='
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | head -n 15
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
        _, out, err = client.exec_command(CLEANUP, timeout=120)
        print(out.read().decode(errors="replace"))
        e = err.read().decode(errors="replace")
        if e.strip():
            print("---[STDERR]---", file=sys.stderr)
            print(e, file=sys.stderr)
    finally:
        client.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
