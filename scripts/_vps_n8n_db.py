import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=30):
    print(f'\n{"="*55}')
    print(f'  {label or cmd[:60]}')
    print('='*55)
    _, stdout, stderr = client.exec_command(f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout)
    stdout.read(); stderr.read()
    sftp = client.open_sftp()
    try:
        with sftp.file('/tmp/out.txt', 'rb') as f:
            raw = f.read()
        safe = raw.decode('utf-8', errors='replace').encode('ascii', errors='replace').decode('ascii')
        print(safe[:4000] or '(sin output)')
    finally:
        sftp.close()

# 1. Ver si hay datos reales en el postgres-data del n8n-queue-mode
run_safe('du -sh /root/n8n-queue-mode/postgres-data/ 2>/dev/null', 'tamaño postgres-data')
run_safe('ls /root/n8n-queue-mode/postgres-data/ 2>/dev/null | head -20', 'contenido postgres-data')

# 2. Levantar postgres temporalmente para ver qué hay adentro
print('\n\n=== Levantando postgres temporal para inspeccionar workflows ===')
script = r"""#!/bin/bash
LOG=/tmp/db_inspect.log
echo "=== $(date) ===" > $LOG

# Arrancar solo el postgres del n8n-queue-mode para leer su contenido
docker run -d --name n8n_inspect_pg \
  -e POSTGRES_USER=n8n_user \
  -e POSTGRES_PASSWORD=n8n_pass \
  -e POSTGRES_DB=n8n_db \
  -v /root/n8n-queue-mode/postgres-data:/var/lib/postgresql/data \
  postgres:13 >> $LOG 2>&1

echo "Esperando 10s que inicie postgres..." >> $LOG
sleep 10

# Contar workflows
echo "--- Workflows ---" >> $LOG
docker exec n8n_inspect_pg psql -U n8n_user -d n8n_db \
  -c "SELECT id, name, active, \"updatedAt\" FROM workflow_entity ORDER BY \"updatedAt\" DESC LIMIT 20;" >> $LOG 2>&1 \
  || echo "tabla workflow_entity no existe o error" >> $LOG

# Ver credentials
echo "--- Credentials ---" >> $LOG
docker exec n8n_inspect_pg psql -U n8n_user -d n8n_db \
  -c "SELECT id, name, type, \"updatedAt\" FROM credentials_entity ORDER BY \"updatedAt\" DESC LIMIT 20;" >> $LOG 2>&1 \
  || echo "tabla credentials_entity no existe" >> $LOG

# Ver executions recientes
echo "--- Executions recientes ---" >> $LOG
docker exec n8n_inspect_pg psql -U n8n_user -d n8n_db \
  -c "SELECT id, \"workflowId\", status, \"startedAt\" FROM execution_entity ORDER BY \"startedAt\" DESC LIMIT 10;" >> $LOG 2>&1 \
  || echo "tabla execution_entity no existe" >> $LOG

# Ver tablas disponibles
echo "--- Tablas disponibles ---" >> $LOG
docker exec n8n_inspect_pg psql -U n8n_user -d n8n_db \
  -c "\dt" >> $LOG 2>&1

# Apagar y eliminar el postgres temporal
docker stop n8n_inspect_pg >> $LOG 2>&1
docker rm n8n_inspect_pg >> $LOG 2>&1
echo "=== FIN $(date) ===" >> $LOG
"""

sftp = client.open_sftp()
with sftp.file('/tmp/db_inspect.sh', 'w') as f:
    f.write(script)
sftp.chmod('/tmp/db_inspect.sh', 0o755)
sftp.close()

client.exec_command('bash /tmp/db_inspect.sh > /tmp/db_inspect_main.log 2>&1 &')
print('Script lanzado. Esperando 40s...')
time.sleep(40)

run_safe('cat /tmp/db_inspect.log', 'contenido DB del n8n-queue-mode')

# 3. Ver también el .env para entender credenciales y dominios
run_safe('cat /root/n8n-queue-mode/.env', 'env completo del n8n-queue-mode')

client.close()
