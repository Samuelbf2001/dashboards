"""TAREA 3a — Inspeccion read-only del fantasma wfhub.

Lista todo lo relacionado a wfhub (servicios swarm, stacks, contenedores,
proyecto en EasyPanel). NO borra nada. Sirve como verificacion pre-limpieza.
"""
import paramiko
import sys

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
echo '===[A] UPTIME / LOAD ANTES ==='
uptime

echo
echo '===[1] DOCKER SERVICE LS (filtrado wfhub) ==='
docker service ls 2>/dev/null | head -n 1
docker service ls 2>/dev/null | grep -i wfhub

echo
echo '===[2] DOCKER SERVICE PS POR SERVICIO ==='
for svc in $(docker service ls --format '{{.Name}}' 2>/dev/null | grep -i wfhub); do
  echo "--- $svc ---"
  docker service ps "$svc" --no-trunc 2>&1
  echo
done

echo
echo '===[3] DOCKER STACK LS (filtrado wfhub) ==='
docker stack ls 2>/dev/null | head -n 1
docker stack ls 2>/dev/null | grep -i wfhub

echo
echo '===[4] /etc/easypanel/projects/ (existe wfhub?) ==='
ls -la /etc/easypanel/projects/ 2>/dev/null | grep -i wfhub
echo '--- listado completo (para contexto) ---'
ls /etc/easypanel/projects/ 2>/dev/null

echo
echo '===[5] DOCKER PS -A wfhub ==='
docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}" | head -n 1
docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}" | grep -i wfhub

echo
echo '===[6] DOCKER NETWORK LS wfhub ==='
docker network ls | grep -i wfhub

echo
echo '===[7] DOCKER VOLUME LS wfhub (solo listar, NO borrar) ==='
docker volume ls | grep -i wfhub

echo
echo '===[8] DOCKER SERVICE INSPECT (detalle del/los servicios wfhub) ==='
for svc in $(docker service ls --format '{{.Name}}' 2>/dev/null | grep -i wfhub); do
  echo "--- $svc ---"
  docker service inspect "$svc" --format 'Image={{.Spec.TaskTemplate.ContainerSpec.Image}} Replicas={{.Spec.Mode.Replicated.Replicas}} CreatedAt={{.CreatedAt}} UpdatedAt={{.UpdatedAt}}'
done
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
