"""Snapshot rapido de CPU/MEM por contenedor + estado del n8n del dashboard."""
import paramiko
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

CMD = r"""
echo '===[A] LOAD AVG ==='
uptime

echo
echo '===[B] DOCKER STATS (snapshot) ==='
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | sort -k2 -rn | head -n 25

echo
echo '===[C] TOP 10 PROCESOS POR CPU ==='
ps -eo pid,user,pcpu,pmem,rss,etime,comm --sort=-pcpu | head -n 11

echo
echo '===[D] N8N DASHBOARD - estado del contenedor ==='
docker ps -a --filter "name=postgres_dashboard-n8n" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

echo
echo '===[E] N8N DASHBOARD - ultimos 50 logs ==='
docker logs --tail 50 postgres_dashboard-n8n-1 2>&1 || echo 'contenedor no existe ahora mismo'

echo
echo '===[F] N8N DASHBOARD - inspect breve ==='
docker inspect postgres_dashboard-n8n-1 --format 'Exit={{.State.ExitCode}} Restarts={{.RestartCount}} OOM={{.State.OOMKilled}} Status={{.State.Status}} StartedAt={{.State.StartedAt}}' 2>&1 || echo 'no existe'

echo
echo '===[G] METABASE DASHBOARD - estado y CPU ==='
docker ps -a --filter "name=postgres_dashboard-metabase" --format "table {{.Names}}\t{{.Status}}"
docker stats --no-stream --format "{{.Name}}: CPU {{.CPUPerc}}  MEM {{.MemUsage}}" postgres_dashboard-metabase-1 2>&1 || true

echo
echo '===[H] ULTIMOS EVENTOS DOCKER (5 min) ==='
docker events --since 5m --until 0s --format '{{.Time}} {{.Action}} {{.Actor.Attributes.name}}' 2>&1 | tail -n 30
"""

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect(HOST, username=USER, password=PASS, timeout=20)
_, out, err = c.exec_command(CMD, timeout=60)
print(out.read().decode(errors='replace'))
e = err.read().decode(errors='replace')
if e.strip():
    print("---[STDERR]---\n" + e, file=sys.stderr)
c.close()
