import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=25):
    print(f'\n--- {label or cmd[:80]} ---')
    _, stdout, stderr = client.exec_command(f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout)
    stdout.read(); stderr.read()
    sftp = client.open_sftp()
    try:
        with sftp.file('/tmp/out.txt', 'rb') as f:
            raw = f.read()
        safe = raw.decode('utf-8', errors='replace').encode('ascii', errors='replace').decode('ascii')
        print(safe[:3000] or '(sin output)')
    finally:
        sftp.close()

# Script que apaga TODO excepto: easypanel, traefik, whatsfull/whatsful y postgres principal
shutdown_script = r"""#!/bin/bash
LOG=/tmp/shutdown2.log
echo "=== APAGADO TOTAL $(date) ===" > $LOG

# 1. Matar procesos n8n-queue-mode via kill -9 directo (mas rapido que compose down)
echo "--- Kill PIDs n8n-queue-mode ---" >> $LOG
pkill -9 -f "n8n-queue-mode" 2>>$LOG || true

# 2. Stop forzado de todos los contenedores n8n-queue-mode
echo "--- Stop contenedores n8n-queue-mode ---" >> $LOG
docker ps --filter "name=n8n-queue-mode" -q | xargs -r docker stop -t 5 >> $LOG 2>&1 || true
docker ps --filter "name=n8n-queue-mode" -q | xargs -r docker rm -f >> $LOG 2>&1 || true

# 3. Bajar compose de n8n-queue-mode (para que no vuelva a arrancar)
echo "--- Compose down n8n-queue-mode ---" >> $LOG
cd /root/n8n-queue-mode && docker compose down --remove-orphans >> $LOG 2>&1 || true

# 4. Renombrar docker-compose para que no vuelva a levantar
echo "--- Deshabilitar compose n8n-queue-mode ---" >> $LOG
mv /root/n8n-queue-mode/docker-compose.yml /root/n8n-queue-mode/docker-compose.yml.disabled 2>>$LOG || true

# 5. Parar metabase (mayor consumo de RAM, libera recursos)
echo "--- Stop metabase ---" >> $LOG
docker stop postgres_dashboard-metabase-1 -t 10 >> $LOG 2>&1 || true

# 6. Parar n8n principal de postgres_dashboard
echo "--- Stop n8n postgres_dashboard ---" >> $LOG
docker stop postgres_dashboard-n8n-1 -t 10 >> $LOG 2>&1 || true

# 7. Stop portal y kuma
echo "--- Stop portal y kuma ---" >> $LOG
docker stop postgres_dashboard-portal-1 -t 5 >> $LOG 2>&1 || true
docker stop postgres_dashboard-uptime-kuma-1 -t 5 >> $LOG 2>&1 || true

# 8. Prune containers parados
docker container prune -f >> $LOG 2>&1 || true

echo "=== FIN APAGADO $(date) ===" >> $LOG
echo "--- Contenedores activos ---" >> $LOG
docker ps --format "table {{.Names}}\t{{.Status}}" >> $LOG
uptime >> $LOG
free -h >> $LOG
"""

sftp = client.open_sftp()
with sftp.file('/tmp/shutdown2.sh', 'w') as f:
    f.write(shutdown_script)
sftp.chmod('/tmp/shutdown2.sh', 0o755)
sftp.close()

print('Script subido. Lanzando apagado...')
client.exec_command('bash /tmp/shutdown2.sh > /tmp/shutdown2_main.log 2>&1 &')
print('Apagado lanzado en background. Esperando 90s...')
time.sleep(90)

print('\n=== LOG APAGADO ===')
run_safe('cat /tmp/shutdown2.log', timeout=15)

print('\n=== CONTENEDORES ACTIVOS ===')
run_safe('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"', timeout=15)

print('\n=== CARGA Y CPU ===')
run_safe('uptime && free -h', timeout=10)
run_safe('ps aux --sort=-%cpu | head -12', timeout=10)

client.close()
print('\n=== APAGADO COMPLETADO ===')
