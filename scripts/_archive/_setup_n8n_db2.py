import paramiko

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

PG = 'postgres_dashboard-postgres-1'

# 1. Ver en qué redes está el postgres ahora
print('=== REDES DEL POSTGRES ===')
run(f'docker inspect {PG} --format "{{{{json .NetworkSettings.Networks}}}}" | python3 -m json.tool | grep -E "^    \\"|\\"IPAddress\\"|\\"Aliases\\"" | head -30')

# 2. Ver qué redes de easypanel existen y sus detalles
print('\n=== RED easypanel-postgres ===')
run('docker network inspect easypanel-postgres --format "{{json .Containers}}" | python3 -m json.tool 2>/dev/null | grep -E "Name|IPv4" | head -20')

# 3. Conectar el postgres a la red easypanel-postgres
print('\n=== CONECTANDO POSTGRES A RED easypanel-postgres ===')
run(f'docker network connect easypanel-postgres {PG} 2>&1 || echo "ya conectado o error"')
run(f'docker network inspect easypanel-postgres --format "{{{{json .Containers}}}}" | python3 -m json.tool 2>/dev/null | grep -E "Name|IPv4" | head -20')

# 4. Crear DB y usuario usando ghl_user
print('\n=== CREANDO DB n8n_pdf Y USUARIO ===')
run(f'''docker exec {PG} psql -U ghl_user -d ghl_analytics -c "
  CREATE USER n8n_pdf_user WITH PASSWORD 'n8npdf2026';
" 2>/dev/null || echo "usuario ya existe"''')

run(f'''docker exec {PG} psql -U ghl_user -d ghl_analytics -c "
  CREATE DATABASE n8n_pdf OWNER n8n_pdf_user;
" 2>/dev/null || echo "DB ya existe"''')

run(f'''docker exec {PG} psql -U ghl_user -d n8n_pdf -c "
  GRANT ALL ON SCHEMA public TO n8n_pdf_user;
" 2>/dev/null''')

# 5. Verificar
run(f'docker exec {PG} psql -U ghl_user -d ghl_analytics -c "\\l n8n_pdf"', 'verificar DB creada')
run(f'docker exec {PG} psql -U ghl_user -d ghl_analytics -c "\\du n8n_pdf_user"', 'verificar usuario creado')

# 6. Ver hostname con el que el n8n de easypanel puede alcanzar el postgres
print('\n=== HOSTNAME PARA EL N8N ===')
run(f'docker inspect {PG} --format "{{{{range .NetworkSettings.Networks}}}}{{{{.IPAddress}}}} {{{{end}}}}"')

# 7. Ver la IP en la red easypanel-postgres específicamente
run(f'docker inspect {PG} --format "{{{{json .NetworkSettings.Networks.easypanel-postgres}}}}" 2>/dev/null | python3 -m json.tool 2>/dev/null | grep IPAddress || echo "revisar nombre de red"')

ssh.close()
print('\n=== LISTO ===')
