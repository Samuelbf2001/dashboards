import paramiko, time, re

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run(cmd, timeout=20):
    print(f'\n$ {cmd[:120]}')
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    result = (out or err).strip()
    safe = result.encode('ascii', errors='replace').decode('ascii')
    print(safe[:3000] or '(sin output)')
    return result

COMPOSE_PATH = '/etc/easypanel/projects/postgres/dashboard/code/docker-compose.yml'

print('=== Leyendo docker-compose del VPS ===')
sftp = client.open_sftp()
with sftp.file(COMPOSE_PATH, 'r') as f:
    compose_content = f.read().decode('utf-8', errors='replace')

print(f'Longitud: {len(compose_content)} chars')
print('Primeras 200 chars del portal section:')
idx = compose_content.find('portal:')
if idx >= 0:
    print(compose_content[idx:idx+600])
else:
    print('[no encontro "portal:" en el compose]')

# Fix: agregar HOSTNAME=0.0.0.0 en la sección environment del portal
# Buscar el bloque environment del portal y agregar HOSTNAME si no está
if 'HOSTNAME: "0.0.0.0"' in compose_content or "HOSTNAME: '0.0.0.0'" in compose_content or 'HOSTNAME=0.0.0.0' in compose_content:
    print('\nHOSTNAME ya está configurado.')
else:
    # Insertar después de "environment:" en la sección portal
    # Estrategia: buscar el bloque del portal y reemplazar el primer "environment:" que sigue
    portal_idx = compose_content.find('portal:')
    if portal_idx >= 0:
        env_idx = compose_content.find('    environment:', portal_idx)
        if env_idx >= 0:
            # Insertar HOSTNAME justo después de "    environment:\n"
            newline_after = compose_content.find('\n', env_idx) + 1
            indent = '      '  # 6 spaces (mismo nivel que otras vars)
            hostname_line = f'{indent}HOSTNAME:                "0.0.0.0"\n'
            compose_fixed = compose_content[:newline_after] + hostname_line + compose_content[newline_after:]
            print('\n=== Compose MODIFICADO (sección portal) ===')
            idx2 = compose_fixed.find('portal:')
            print(compose_fixed[idx2:idx2+700])

            # Hacer backup y escribir
            with sftp.file(COMPOSE_PATH + '.bak', 'w') as f:
                f.write(compose_content)
            with sftp.file(COMPOSE_PATH, 'w') as f:
                f.write(compose_fixed)
            print('\nCompose actualizado en VPS.')
        else:
            print('[ERROR] No se encontro "environment:" en la seccion portal')
    else:
        print('[ERROR] No se encontro "portal:" en el compose')

sftp.close()

print('\n=== Reiniciando portal ===')
# Usar docker compose para recrear solo el portal
script = f"""
cd /
docker compose -p postgres_dashboard -f {COMPOSE_PATH} up -d --no-deps portal > /tmp/portal_restart.log 2>&1
echo "exit: $?" >> /tmp/portal_restart.log
"""
sftp2 = client.open_sftp()
with sftp2.file('/tmp/restart_portal.sh', 'w') as f:
    f.write(script)
sftp2.chmod('/tmp/restart_portal.sh', 0o755)
sftp2.close()

client.exec_command('bash /tmp/restart_portal.sh > /tmp/restart_main.log 2>&1 &')
print('Reinicio lanzado en background. Esperando 30s...')
time.sleep(30)

run('cat /tmp/portal_restart.log')

print('\n=== Estado del portal ===')
run('docker ps --filter "name=portal" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"')

print('\n=== Test healthcheck manual ===')
run('docker exec postgres_dashboard-portal-1 netstat -tlnp 2>/dev/null | grep 4000')
run('wget -qO- http://127.0.0.1:4000/ --timeout=5 2>&1 | head -3 || echo "no accesible desde host"')
run('docker inspect postgres_dashboard-portal-1 --format "Health: {{.State.Health.Status}} | Streak: {{.State.Health.FailingStreak}}" 2>/dev/null')

print('\n=== Carga final ===')
run('uptime && free -h')

client.close()
print('\n=== FIN FIX PORTAL ===')
