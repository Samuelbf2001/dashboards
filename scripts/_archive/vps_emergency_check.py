"""Chequeo de emergencia: estado actual de Docker, Swarm, EasyPanel y servicios."""
import paramiko
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

CMD = r"""
echo '===[A] UPTIME / LOAD ==='
uptime

echo
echo '===[B] DOCKER DAEMON STATUS ==='
systemctl status docker --no-pager | head -n 15

echo
echo '===[C] SWARM NODE STATUS ==='
docker node ls 2>&1
echo
docker info --format 'Swarm: {{.Swarm.LocalNodeState}} | Managers: {{.Swarm.Managers}} | Nodes: {{.Swarm.Nodes}}' 2>&1

echo
echo '===[D] TODOS LOS SERVICIOS SWARM ==='
docker service ls 2>&1

echo
echo '===[E] CONTENEDORES CORRIENDO AHORA ==='
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>&1

echo
echo '===[F] CONTENEDORES TOTAL (incluyendo apagados) ==='
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}" | head -n 40

echo
echo '===[G] EASYPANEL CONTENEDOR ==='
docker ps -a --filter "name=easypanel" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

echo
echo '===[H] DMESG ULTIMOS (OOM / kernel) ==='
dmesg -T --level=err,warn,crit 2>/dev/null | tail -n 30

echo
echo '===[I] DOCKER EVENTS ULTIMOS 30 MIN ==='
docker events --since 30m --until 0s --filter event=die --filter event=stop --filter event=kill --format '{{.Time}} {{.Type}} {{.Action}} {{.Actor.Attributes.name}}' 2>&1 | tail -n 40

echo
echo '===[J] JOURNALCTL DOCKER ULTIMOS ERRORES ==='
journalctl -u docker --since '30 min ago' --no-pager -p err 2>/dev/null | tail -n 30

echo
echo '===[K] MEMORIA / OOM ==='
free -h
echo '--- OOM kills en kernel log ---'
dmesg -T 2>/dev/null | grep -i 'killed process\|out of memory' | tail -n 10
"""


def main() -> int:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(HOST, username=USER, password=PASS, timeout=20)
    except Exception as e:
        print(f"[ERROR SSH] {e}", file=sys.stderr)
        return 1
    try:
        _, out, err = client.exec_command(CMD, timeout=120)
        print(out.read().decode(errors="replace"))
        e = err.read().decode(errors="replace")
        if e.strip():
            print("---[STDERR]---\n" + e, file=sys.stderr)
    finally:
        client.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
