import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=30):
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

# 1. Ver data de EasyPanel para entender si gestiona n8n-queue-mode
run_safe('ls -la /etc/easypanel/data/', 'easypanel data dir')
run_safe('ls -la /etc/easypanel/actions/ | tail -20', 'easypanel actions dir')
run_safe('cat /etc/easypanel/data/*.json 2>/dev/null | python3 -m json.tool 2>/dev/null | grep -i "n8n-queue\\|n8n_queue" | head -20 || grep -r "n8n-queue" /etc/easypanel/data/ 2>/dev/null | head -10 || echo "no encontrado en data"', 'buscar n8n-queue en easypanel data')

# 2. Leer el bash history para ver quien hizo docker compose up recientemente
run_safe('tail -30 /root/.bash_history 2>/dev/null | grep -v "^#"', 'bash history reciente')

# 3. Matar todo de n8n-queue-mode PERMANENTEMENTE
print('\n\n=== MATANDO n8n-queue-mode PERMANENTE ===')
script = r"""#!/bin/bash
LOG=/tmp/kill_perm.log
echo "=== $(date) ===" > $LOG

# Stop y rm forzado
echo "--- Stop forzado ---" >> $LOG
docker ps --filter "name=n8n-queue-mode" -q | xargs -r docker stop -t 3 >> $LOG 2>&1 || true
docker ps -a --filter "name=n8n-queue-mode" -q | xargs -r docker rm -f >> $LOG 2>&1 || true

# Eliminar TODOS los compose files del directorio
echo "--- Eliminando compose files ---" >> $LOG
rm -f /root/n8n-queue-mode/docker-compose.yml >> $LOG 2>&1
rm -f /root/n8n-queue-mode/docker-compose.yml.disabled >> $LOG 2>&1
ls /root/n8n-queue-mode/ >> $LOG 2>&1

# Crear un docker-compose.yml que no tenga servicios (para que compose no levante nada)
cat > /root/n8n-queue-mode/docker-compose.yml << 'COMPOSEOF'
# DISABLED - apagado por mantenimiento
services: {}
COMPOSEOF
echo "--- Compose vacío creado ---" >> $LOG
cat /root/n8n-queue-mode/docker-compose.yml >> $LOG

echo "=== FIN $(date) ===" >> $LOG
docker ps --filter "name=n8n-queue-mode" >> $LOG
"""

sftp = client.open_sftp()
with sftp.file('/tmp/kill_perm.sh', 'w') as f:
    f.write(script)
sftp.chmod('/tmp/kill_perm.sh', 0o755)
sftp.close()

client.exec_command('bash /tmp/kill_perm.sh > /tmp/kill_perm_main.log 2>&1 &')
print('Script lanzado. Esperando 30s...')
time.sleep(30)

run_safe('cat /tmp/kill_perm.log', 'log kill permanente')
run_safe('docker ps --filter "name=n8n-queue-mode" --format "{{.Names}} {{.Status}}" || echo "sin contenedores"', 'verificar n8n-queue-mode')
run_safe('uptime && free -h', 'carga actual')
run_safe('ps aux --sort=-%cpu | head -10', 'top cpu')

client.close()
