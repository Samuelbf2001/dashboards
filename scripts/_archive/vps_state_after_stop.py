"""Estado post-stop: confirmar que no hay procesos compose colgados, ver que falta pullear,
y dejar el terreno limpio para un deploy directo via SSH."""
import paramiko
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

CMD = r"""
echo '===[A] LOAD ==='
uptime

echo
echo '===[B] PROCESOS COMPOSE ACTIVOS (deberia estar vacio) ==='
ps -eo pid,etime,user,args | grep -E 'docker.compose|docker compose' | grep -v grep

echo
echo '===[C] PROCESOS PULL/BUILD ACTIVOS (unpigz, buildkit) ==='
ps -eo pid,etime,pcpu,args | grep -E 'unpigz|gunzip|buildkit' | grep -v grep | head -10

echo
echo '===[D] CONTENEDORES POSTGRES_DASHBOARD ==='
docker ps -a --filter "name=postgres_dashboard" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"

echo
echo '===[E] IMAGENES n8n / metabase disponibles ==='
docker images | grep -E '^(n8nio|metabase|postgres_dashboard)' | head -10

echo
echo '===[F] ESPACIO EN DISCO ==='
df -h /

echo
echo '===[G] DOCKER COMPOSE FILES Y .ENV ==='
ls -la /etc/easypanel/projects/postgres/dashboard/code/ 2>&1 | head -20

echo
echo '===[H] N8N_ENCRYPTION_KEY actual en .env ==='
grep -E 'N8N_ENCRYPTION_KEY' /etc/easypanel/projects/postgres/dashboard/code/.env 2>&1
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
