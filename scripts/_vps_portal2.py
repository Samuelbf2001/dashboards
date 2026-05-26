import paramiko, time

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=20):
    print(f'\n--- {label or cmd[:80]} ---')
    _, stdout, stderr = client.exec_command(
        f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout
    )
    stdout.read(); stderr.read()
    sftp = client.open_sftp()
    try:
        with sftp.file('/tmp/out.txt', 'rb') as f:
            raw = f.read()
        result = raw.decode('utf-8', errors='replace')
        safe = result.encode('ascii', errors='replace').decode('ascii')
        print(safe[:3000] or '(sin output)')
        return result
    finally:
        sftp.close()

def run(cmd, timeout=15):
    print(f'\n$ {cmd[:100]}')
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    result = (out or err).strip()
    safe = result.encode('ascii', errors='replace').decode('ascii')
    print(safe or '(sin output)')
    return result

PORTAL = 'postgres_dashboard-portal-1'

print('=== QUE PUERTOS ESCUCHA EL PORTAL ===')
run_safe(f'docker exec {PORTAL} ss -tlnp 2>/dev/null || docker exec {PORTAL} netstat -tlnp 2>/dev/null', 'puertos')

print('\n=== PROBAR DESDE DENTRO DEL CONTENEDOR ===')
run_safe(f'docker exec {PORTAL} wget -qO- http://localhost:4000/ 2>&1 | head -5', 'wget localhost')
run_safe(f'docker exec {PORTAL} wget -qO- http://0.0.0.0:4000/ 2>&1 | head -5', 'wget 0.0.0.0')
run_safe(f'docker exec {PORTAL} wget -qO- http://172.20.0.5:4000/ 2>&1 | head -5', 'wget container IP')

print('\n=== SERVER.JS DEL PORTAL ===')
run_safe(f'docker exec {PORTAL} cat /app/server.js 2>/dev/null || docker exec {PORTAL} cat /app/.next/standalone/server.js 2>/dev/null | head -30', 'server.js')

print('\n=== PACKAGE.JSON ===')
run_safe(f'docker exec {PORTAL} cat /app/package.json 2>/dev/null | head -20', 'package.json')

print('\n=== VARIABLES RELEVANTES ===')
run_safe(f'docker exec {PORTAL} env | grep -E "HOST|PORT|NODE|NEXT" | grep -v -iE "secret|password|key"', 'env vars')

print('\n=== LOGS COMPLETOS (ultimos 100 lineas) ===')
run_safe(f'docker logs --tail 100 {PORTAL} 2>&1', 'logs portal')

print('\n=== CARGA ACTUAL ===')
run('uptime')
run('free -h')

client.close()
