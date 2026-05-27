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

print('=== LOG RESTART PORTAL ===')
run_safe('cat /tmp/portal_restart.log')

print('\n=== TODOS LOS CONTENEDORES ===')
run_safe('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"')

print('\n=== ESTADO SALUD PORTAL ===')
run_safe('docker inspect postgres_dashboard-portal-1 --format "Status={{.State.Status}} Health={{.State.Health.Status}} Streak={{.State.Health.FailingStreak}}" 2>/dev/null || echo "container no encontrado"')

print('\n=== PUERTOS QUE ESCUCHA EL PORTAL ===')
run_safe('docker exec postgres_dashboard-portal-1 netstat -tlnp 2>/dev/null | head -10 || echo "no disponible"')

print('\n=== VARIABLES ENV DEL PORTAL (sin secrets) ===')
run_safe('docker inspect postgres_dashboard-portal-1 --format "{{range .Config.Env}}{{println .}}{{end}}" | grep -v -iE "password|secret|key|token" | grep -E "HOST|PORT|NODE|NEXT"')

print('\n=== TEST HEALTHCHECK DESDE DENTRO ===')
run_safe('docker exec postgres_dashboard-portal-1 wget -qO- http://127.0.0.1:4000/ 2>&1 | head -3')

print('\n=== CARGA ===')
run('uptime && free -h')

print('\n=== TOP PROCESOS ===')
run_safe('ps aux --sort=-%cpu | head -12')

client.close()
