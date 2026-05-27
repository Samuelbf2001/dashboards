import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_bg(cmd, label=''):
    """Envía comando en background al VPS, no espera respuesta."""
    print(f'\n[BG] {label or cmd[:80]}')
    _, stdout, stderr = client.exec_command(f'nohup bash -c "{cmd}" > /tmp/cleanup.log 2>&1 &', timeout=10)
    time.sleep(1)
    print('  -> disparado en background')

def run(cmd, timeout=15, label=''):
    print(f'\n$ {label or cmd[:80]}')
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    result = (out or err).strip()
    print(result or '(sin output)')
    return result

# ---- Subir script de limpieza al VPS ----
print('=== Subiendo script de limpieza al VPS ===')

script = r"""#!/bin/bash
set -e
LOG=/tmp/cleanup_detail.log
echo "=== INICIO $(date) ===" >> $LOG

echo "--- Bajando n8n-queue-mode ---" >> $LOG
cd /root/n8n-queue-mode
docker compose down --remove-orphans >> $LOG 2>&1 || true
echo "--- n8n-queue-mode OK ---" >> $LOG

echo "--- Bajando proyecto code (duplicado) ---" >> $LOG
docker compose -p code \
  -f /etc/easypanel/projects/postgres/dashboard/code/docker-compose.yml \
  down --remove-orphans >> $LOG 2>&1 || true
echo "--- code OK ---" >> $LOG

echo "--- Limpiando contenedores stopped ---" >> $LOG
docker container prune -f >> $LOG 2>&1 || true

echo "--- Estado final ---" >> $LOG
docker ps --format "table {{.Names}}\t{{.Status}}" >> $LOG 2>&1
uptime >> $LOG
free -h >> $LOG

echo "=== FIN $(date) ===" >> $LOG
"""

# Escribir el script en el VPS via SFTP
sftp = client.open_sftp()
with sftp.file('/tmp/vps_cleanup.sh', 'w') as f:
    f.write(script)
sftp.chmod('/tmp/vps_cleanup.sh', 0o755)
sftp.close()
print('Script subido: /tmp/vps_cleanup.sh')

# Ejecutar en background
print('\n=== Ejecutando script en background ===')
client.exec_command('bash /tmp/vps_cleanup.sh > /tmp/cleanup_main.log 2>&1 &')
print('Script lanzado. Esperando 30 segundos...')
time.sleep(30)

# Leer el log
print('\n=== Log de progreso ===')
result = run('cat /tmp/cleanup_detail.log 2>/dev/null || cat /tmp/cleanup_main.log 2>/dev/null || echo "aun ejecutando"', timeout=10)

print('\n=== Estado actual de contenedores ===')
run('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null', timeout=10)

print('\n=== Carga del sistema ===')
run('uptime && free -h', timeout=10)

client.close()
print('\n=== Script enviado ===')
