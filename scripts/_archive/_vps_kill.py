import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=20):
    print(f'\n--- {label or cmd[:80]} ---')
    _, stdout, stderr = client.exec_command(f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout)
    stdout.read(); stderr.read()
    sftp = client.open_sftp()
    try:
        with sftp.file('/tmp/out.txt', 'rb') as f:
            raw = f.read()
        safe = raw.decode('utf-8', errors='replace').encode('ascii', errors='replace').decode('ascii')
        print(safe[:3000] or '(sin output)')
        return safe
    finally:
        sftp.close()

print('=== CARGA Y TOP CPU ===')
run_safe('uptime && echo "" && ps aux --sort=-%cpu | head -15')

print('\n=== DOCKER STATS SNAPSHOT ===')
run_safe('docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | sort -t% -k1 -rn 2>/dev/null || docker stats --no-stream --format "{{.Name}} CPU={{.CPUPerc}} MEM={{.MemUsage}}"', timeout=30)

# Script de apagado masivo — deja solo lo esencial
shutdown_script = r"""#!/bin/bash
LOG=/tmp/shutdown.log
echo "=== APAGADO $(date) ===" > $LOG

echo "--- Parando n8n-queue-mode ---" >> $LOG
cd /root/n8n-queue-mode && docker compose down --remove-orphans >> $LOG 2>&1 || true

echo "--- Parando postgres_dashboard-portal, n8n, metabase, kuma (no esenciales ahora) ---" >> $LOG
docker stop postgres_dashboard-portal-1 >> $LOG 2>&1 || true
docker stop postgres_dashboard-n8n-1 >> $LOG 2>&1 || true
docker stop postgres_dashboard-metabase-1 >> $LOG 2>&1 || true
docker stop postgres_dashboard-uptime-kuma-1 >> $LOG 2>&1 || true

echo "--- Pruning stopped ---" >> $LOG
docker container prune -f >> $LOG 2>&1 || true

echo "--- Estado final ---" >> $LOG
docker ps --format "table {{.Names}}\t{{.Status}}" >> $LOG
uptime >> $LOG
echo "=== FIN APAGADO $(date) ===" >> $LOG
"""

sftp = client.open_sftp()
with sftp.file('/tmp/shutdown_all.sh', 'w') as f:
    f.write(shutdown_script)
sftp.chmod('/tmp/shutdown_all.sh', 0o755)
sftp.close()

print('\n=== LANZANDO APAGADO MASIVO EN BACKGROUND ===')
client.exec_command('bash /tmp/shutdown_all.sh > /tmp/shutdown_main.log 2>&1 &')
print('Apagado lanzado. Esperando 60s...')
time.sleep(60)

print('\n=== LOG APAGADO ===')
run_safe('cat /tmp/shutdown.log')

print('\n=== ESTADO FINAL ===')
run_safe('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"')
run_safe('uptime && free -h')
run_safe('ps aux --sort=-%cpu | head -10')

client.close()
