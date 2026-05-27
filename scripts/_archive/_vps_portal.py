import paramiko, time, sys, io

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
    # strip non-printable for Windows console
    safe = result.encode('ascii', errors='replace').decode('ascii')
    print(safe or '(sin output)')
    return result

def run_safe(cmd, timeout=20):
    """Run and save to file to avoid encoding issues."""
    _, stdout, stderr = client.exec_command(
        f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout
    )
    stdout.read()
    # Read via SFTP
    sftp = client.open_sftp()
    try:
        with sftp.file('/tmp/out.txt', 'rb') as f:
            raw = f.read()
        result = raw.decode('utf-8', errors='replace')
        safe = result.encode('ascii', errors='replace').decode('ascii')
        print(safe[:4000])
        return result
    finally:
        sftp.close()

print('='*60)
print('DIAGNOSTICO PORTAL')
print('='*60)

print('\n--- Healthcheck state ---')
run_safe('docker inspect postgres_dashboard-portal-1 --format "{{json .State.Health}}" | python3 -m json.tool')

print('\n--- Logs recientes ---')
run_safe('docker logs --tail 60 postgres_dashboard-portal-1 2>&1')

print('\n--- Variables de entorno (sin secrets) ---')
run_safe('docker inspect postgres_dashboard-portal-1 --format "{{range .Config.Env}}{{println .}}{{end}}" | grep -v -iE "password|secret|key|token"')

print('\n--- Imagen y CMD ---')
run('docker inspect postgres_dashboard-portal-1 --format "Image: {{.Config.Image}} | Cmd: {{.Config.Cmd}} | Entrypoint: {{.Config.Entrypoint}}"')

print('\n--- Network del portal ---')
run('docker inspect postgres_dashboard-portal-1 --format "{{json .NetworkSettings.Networks}}" | python3 -m json.tool 2>/dev/null | grep -E "IPAddress|Gateway|NetworkID" | head -10')

print('\n--- Test healthcheck manual ---')
run_safe('docker exec postgres_dashboard-portal-1 wget -qO- http://127.0.0.1:4000/api/health 2>&1 || docker exec postgres_dashboard-portal-1 curl -s http://127.0.0.1:4000/api/health 2>&1 || echo "no wget/curl disponible"')

print('\n--- Procesos dentro del portal ---')
run_safe('docker exec postgres_dashboard-portal-1 ps aux 2>&1 || echo "no disponible"')

print('\n--- Estado actual containers y carga ---')
run('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"')
run('uptime')

client.close()
print('\n=== FIN DIAGNOSTICO PORTAL ===')
