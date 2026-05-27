"""Diagnostico read-only del VPS de produccion.

No modifica ni apaga nada. Solo recolecta metricas para identificar fuentes
de congestion (CPU, memoria, disco, IO, contenedores Docker, procesos).
"""
import paramiko
import sys

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
echo '===[1] UPTIME / LOAD AVG ==='
uptime

echo
echo '===[2] CPU TOTAL (snapshot) ==='
top -bn1 | head -n 5

echo
echo '===[3] MEMORIA ==='
free -h

echo
echo '===[4] DISCO ==='
df -h / /var/lib/docker /var/log 2>/dev/null

echo
echo '===[5] TOP 15 PROCESOS POR CPU ==='
ps -eo pid,user,pcpu,pmem,rss,etime,comm --sort=-pcpu | head -n 16

echo
echo '===[6] TOP 15 PROCESOS POR MEMORIA ==='
ps -eo pid,user,pcpu,pmem,rss,etime,comm --sort=-rss | head -n 16

echo
echo '===[7] DOCKER STATS (no-stream) ==='
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"

echo
echo '===[8] DOCKER PS -A (ver restarts/exited) ==='
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | head -n 60

echo
echo '===[9] CONTENEDORES EN RESTART LOOP ==='
docker ps -a --filter "status=restarting" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

echo
echo '===[10] SYSTEMD CGROUPS TOP (servicios consumiendo CPU/mem) ==='
systemd-cgtop -n 1 -b --depth=2 2>/dev/null | head -n 25

echo
echo '===[11] I/O WAIT (vmstat 1 5) ==='
vmstat 1 5

echo
echo '===[12] CONEXIONES TCP (resumen + top puertos establecidos) ==='
ss -s
echo '--- top puertos con conexiones establecidas ---'
ss -tan state established 2>/dev/null | awk 'NR>1{print $4}' | awk -F: '{print $NF}' | sort | uniq -c | sort -rn | head -n 10

echo
echo '===[13] DMESG errores/warnings recientes (OOM, IO) ==='
dmesg -T --level=err,warn 2>/dev/null | tail -n 20

echo
echo '===[14] DOCKER DISK USAGE ==='
docker system df

echo
echo '===[15] CONTENEDORES MAS PESADOS EN DISCO ==='
docker ps -as --format "table {{.Names}}\t{{.Size}}" | head -n 30

echo
echo '===[16] LOGS RECIENTES DEL CONTENEDOR PROBLEMATICO (wfhub si existe) ==='
docker ps -a --format "{{.Names}}" | grep -i wfhub | head -n 5 | while read c; do
  echo "--- $c (ultimas 5 lineas) ---"
  docker logs --tail 5 "$c" 2>&1
done

echo
echo '===[17] FECHA / ZONA ==='
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
