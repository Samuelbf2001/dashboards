"""Diagnostico del docker-compose que lleva 20 min: ver progreso, IO de red, layers en pull."""
import paramiko
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

CMD = r"""
echo '===[A] Procesos docker-compose y sus argumentos ==='
ps -eo pid,etime,user,args | grep -E 'docker.compose|docker compose' | grep -v grep

echo
echo '===[B] CWD de cada proceso compose (donde se ejecuto) ==='
for pid in $(pgrep -f 'docker.compose|docker compose'); do
  echo "--- PID $pid ---"
  ls -la /proc/$pid/cwd 2>&1
done

echo
echo '===[C] Procesos relacionados al pull/build ==='
ps -eo pid,etime,pcpu,pmem,args --sort=-pcpu | grep -E 'unpigz|gunzip|tar|containerd|buildkit' | grep -v grep | head -20

echo
echo '===[D] IO disco en este momento ==='
iostat -xz 1 2 2>/dev/null | tail -n 20 || vmstat 1 3

echo
echo '===[E] Conexiones de red salientes (a registries) ==='
ss -tn state established 2>/dev/null | awk 'NR>1{print $5}' | sort | uniq -c | sort -rn | head -20

echo
echo '===[F] Espacio libre en /var/lib/docker ==='
df -h /var/lib/docker /

echo
echo '===[G] Pulls activos en containerd ==='
ctr -n moby image list 2>/dev/null | head -20 || echo 'ctr no disponible'

echo
echo '===[H] Imagenes recientes descargadas/creadas ==='
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}" | head -15

echo
echo '===[I] Eventos Docker de los ultimos 10 min relacionados a pull/create ==='
docker events --since 10m --until 0s --format '{{.Time}} {{.Type}} {{.Action}} {{.Actor.Attributes.name}}' 2>&1 | grep -E 'pull|create|start' | tail -30
"""

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect(HOST, username=USER, password=PASS, timeout=20)
_, out, err = c.exec_command(CMD, timeout=90)
print(out.read().decode(errors='replace'))
e = err.read().decode(errors='replace')
if e.strip():
    print("---[STDERR]---\n" + e, file=sys.stderr)
c.close()
