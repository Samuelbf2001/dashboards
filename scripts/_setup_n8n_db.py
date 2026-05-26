import paramiko, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('72.60.67.214', username='root', password='Sixteam2026-', timeout=15)

def run(cmd, label='', timeout=20):
    print(f'\n--- {label or cmd[:80]} ---')
    _, stdout, stderr = ssh.exec_command(f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout)
    stdout.read(); stderr.read()
    sftp = ssh.open_sftp()
    try:
        with sftp.file('/tmp/out.txt','rb') as f:
            raw = f.read()
        out = raw.decode('utf-8', errors='replace').encode('ascii', errors='replace').decode('ascii')
        print(out[:3000] or '(sin output)')
        return out
    finally:
        sftp.close()

# 1. Ver todos los contenedores incluyendo los nuevos de easypanel
print('=== CONTENEDORES ACTUALES ===')
run('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"')

# 2. Ver redes del proyecto postgres (para saber cómo se llaman los servicios)
print('\n=== REDES DOCKER ===')
run('docker network ls')

# 3. Crear DB n8n_pdf en el postgres existente
print('\n=== CREANDO DB PARA NUEVO N8N ===')
run('''docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics -c "
  SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='n8n_pdf' AND pid <> pg_backend_pid();
" 2>/dev/null || true''', 'terminar conexiones previas')

run('''docker exec postgres_dashboard-postgres-1 psql -U postgres -c "
  SELECT 1 FROM pg_database WHERE datname='n8n_pdf'
" 2>/dev/null || docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics -c "\\\\l"''',
'verificar databases existentes')

# Crear user y DB para el nuevo n8n
run('''docker exec postgres_dashboard-postgres-1 bash -c "
  psql -U postgres -c \\"CREATE USER n8n_pdf_user WITH PASSWORD 'n8npdf2026';\\" 2>/dev/null || true
  psql -U postgres -c \\"CREATE DATABASE n8n_pdf OWNER n8n_pdf_user;\\" 2>/dev/null || true
  psql -U postgres -c \\"GRANT ALL PRIVILEGES ON DATABASE n8n_pdf TO n8n_pdf_user;\\" 2>/dev/null || true
  psql -U postgres -d n8n_pdf -c \\"GRANT ALL ON SCHEMA public TO n8n_pdf_user;\\" 2>/dev/null || true
  psql -U postgres -c \\"\\\\l\\"
"''', 'crear user n8n_pdf_user y DB n8n_pdf', timeout=30)

# 4. Ver hostname accesible del postgres desde la red easypanel
print('\n=== HOSTNAME POSTGRES EN RED EASYPANEL ===')
run('docker inspect postgres_dashboard-postgres-1 --format "{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}" 2>/dev/null')
run('docker inspect postgres_dashboard-postgres-1 --format "{{json .NetworkSettings.Networks}}" | python3 -m json.tool | grep -E "NetworkID|IPAddress|Aliases" | head -20')

# 5. Ver si hay contenedores del nuevo n8n/gotenberg ya corriendo
print('\n=== CONTENEDORES N8N/GOTENBERG NUEVOS ===')
run('docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -iE "n8n|gotenberg" || echo "ninguno encontrado"')

ssh.close()
