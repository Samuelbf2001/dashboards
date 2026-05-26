import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run(cmd, timeout=20):
    print(f'\n$ {cmd[:100]}')
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    result = (out or err).strip()
    print(result or '(sin output)')
    return result

print('=== ESTADO TRAS LIMPIEZA ===')
run('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"')

print('\n=== CARGA ===')
run('uptime && free -h')

print('\n=== TOP PROCESOS CPU ===')
run('ps aux --sort=-%cpu | head -15')

print('\n=== LOGS PORTAL (latin-1) ===')
# Leer logs del portal con encoding correcto via script shell
_, stdout, _ = client.exec_command(
    "docker logs --tail 50 postgres_dashboard-portal-1 2>&1 | cat", timeout=15
)
raw = stdout.read()
try:
    decoded = raw.decode('utf-8', errors='replace')
except:
    decoded = raw.decode('latin-1', errors='replace')
print(decoded[:3000])

print('\n=== INSPECT HEALTHCHECK PORTAL ===')
run('docker inspect postgres_dashboard-portal-1 --format "{{json .State.Health}}" 2>/dev/null | python3 -m json.tool 2>/dev/null | head -40')

print('\n=== ENV PORTAL ===')
run('docker inspect postgres_dashboard-portal-1 --format "{{range .Config.Env}}{{.}}\n{{end}}" 2>/dev/null | grep -v -i pass | grep -v -i secret | grep -v -i key')

client.close()
