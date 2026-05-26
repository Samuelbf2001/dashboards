"""READ-ONLY: descubrir como EasyPanel inyecta secretos (version sin docker events)."""
import paramiko
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
set +e
timeout 5 echo ok >/dev/null

echo '===[1] EASYPANEL: estructura del directorio postgres/dashboard ==='
ls -la /etc/easypanel/projects/postgres/dashboard/ 2>&1
echo '---'
ls -la /etc/easypanel/projects/postgres/ 2>&1 | head -n 20

echo
echo '===[2] EASYPANEL ROOT ==='
ls -la /etc/easypanel/ 2>&1 | head -n 40

echo
echo '===[3] DOCKER PS -A FILTRADO postgres_dashboard ==='
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Image}}' 2>&1 | grep -iE 'postgres_dashboard|NAMES' | head -n 30

echo
echo '===[4] BUSCAR archivos de config de EasyPanel (sin recursion profunda) ==='
ls -la /etc/easypanel/db/ 2>&1 | head -n 20
ls -la /etc/easypanel/data/ 2>&1 | head -n 20
ls -la /etc/easypanel/state/ 2>&1 | head -n 20

echo
echo '===[5] BUSCAR json con N8N_ENCRYPTION_KEY (timeout 10s) ==='
timeout 10 grep -rlE 'N8N_ENCRYPTION_KEY' /etc/easypanel/ 2>/dev/null | head -n 10
echo '---'
timeout 10 grep -rlE 'MB_DB_PASS' /etc/easypanel/ 2>/dev/null | head -n 10

echo
echo '===[6] BUSCAR la key 663a1244 en /etc/easypanel (timeout 10s) ==='
timeout 10 grep -rlE '663a1244' /etc/easypanel/ 2>/dev/null | head -n 10

echo
echo '===[7] Procesos docker compose actuales ==='
ps -eo pid,etime,user,cmd 2>&1 | grep -iE 'docker.*compose|docker-compose' | grep -v grep | head -n 10

echo
echo '===[8] Eventos docker recientes vistos en log ==='
journalctl -u docker.service -n 30 --no-pager 2>&1 | tail -n 30
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
