import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run(cmd, timeout=20, label=''):
    print(f'\n$ {label or cmd[:100]}')
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    result = (out or err).strip()
    print(result or '(sin output)')
    return result

print('=== LOG COMPLETO DEL SCRIPT ANTERIOR ===')
run('cat /tmp/cleanup_detail.log', timeout=15)

print('\n\n=== CONTENEDORES RESTANTES A DETENER ===')
run('docker ps --filter "name=n8n-queue-mode" --filter "name=code-" --format "table {{.Names}}\t{{.Status}}"', timeout=10)

# Subir segundo script para los restantes
script2 = r"""#!/bin/bash
LOG=/tmp/cleanup2.log
echo "=== INICIO FASE 2 $(date) ===" >> $LOG

# Forzar stop de contenedores n8n-queue-mode que quedaron
echo "--- Stop forzado n8n-queue-mode ---" >> $LOG
docker stop n8n-queue-mode-postgres-1 n8n-queue-mode-redis-1 n8n-queue-mode-n8n-1 n8n-queue-mode-gotenberg1-1 2>>$LOG || true
docker rm n8n-queue-mode-postgres-1 n8n-queue-mode-redis-1 n8n-queue-mode-n8n-1 n8n-queue-mode-gotenberg1-1 2>>$LOG || true
echo "--- n8n-queue-mode limpio ---" >> $LOG

# Bajar proyecto code
echo "--- Bajando proyecto code ---" >> $LOG
docker stop code-portal-1 code-postgres-1 code-uptime-kuma-1 2>>$LOG || true
docker rm code-portal-1 code-postgres-1 code-uptime-kuma-1 2>>$LOG || true
echo "--- code limpio ---" >> $LOG

# Limpiar stopped containers
echo "--- Pruning stopped containers ---" >> $LOG
docker container prune -f >> $LOG 2>&1

echo "=== FIN FASE 2 $(date) ===" >> $LOG
echo "--- Contenedores activos ---" >> $LOG
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" >> $LOG
echo "--- Carga ---" >> $LOG
uptime >> $LOG
free -h >> $LOG
"""

sftp = client.open_sftp()
with sftp.file('/tmp/vps_cleanup2.sh', 'w') as f:
    f.write(script2)
sftp.chmod('/tmp/vps_cleanup2.sh', 0o755)
sftp.close()
print('\nScript fase 2 subido. Ejecutando...')
client.exec_command('bash /tmp/vps_cleanup2.sh > /tmp/cleanup2_main.log 2>&1 &')
print('Esperando 40 segundos...')
time.sleep(40)

print('\n=== LOG FASE 2 ===')
run('cat /tmp/cleanup2.log', timeout=15)

print('\n=== ESTADO FINAL DE CONTENEDORES ===')
run('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"', timeout=15)

print('\n=== CARGA DEL SISTEMA ===')
run('uptime && free -h', timeout=10)

print('\n=== TOP PROCESOS CPU ===')
run('ps aux --sort=-%cpu | head -12', timeout=10)

client.close()
