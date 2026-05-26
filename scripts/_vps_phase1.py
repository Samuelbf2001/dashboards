import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=15)

def run(cmd, timeout=60):
    print(f'\n$ {cmd}')
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    result = (out or err).strip()
    print(result)
    return result

print('='*60)
print('FASE 1 — Detener n8n-queue-mode')
print('='*60)

# Verificar que existe
run('ls /root/n8n-queue-mode/')

# Bajar el stack
run('cd /root/n8n-queue-mode && docker compose down', timeout=90)

# Verificar que bajó
time.sleep(3)
run('docker ps | grep n8n-queue-mode || echo "OK — sin contenedores n8n-queue-mode"')

print('\n' + '='*60)
print('FASE 2 — Detener proyecto code (duplicado)')
print('='*60)

# Ver el compose file
run('cat /etc/easypanel/projects/postgres/dashboard/code/docker-compose.yml | head -20')

# Identificar contenedores del proyecto code
run('docker ps --filter "name=code-" --format "table {{.Names}}\t{{.Status}}"')

# Bajar solo el proyecto code (NO el postgres_dashboard)
run('docker compose -p code -f /etc/easypanel/projects/postgres/dashboard/code/docker-compose.yml down', timeout=90)

time.sleep(3)
run('docker ps --filter "name=code-" || echo "OK — sin contenedores code-"')

print('\n' + '='*60)
print('ESTADO TRAS FASES 1 y 2')
print('='*60)
run('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"')
run('uptime')
run('free -h')

client.close()
print('\n=== FASES 1 y 2 COMPLETADAS ===')
