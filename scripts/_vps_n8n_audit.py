import paramiko

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=20):
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

# 1. Ver el compose actual (vacío) y los bak para entender la config original
run_safe('cat /root/n8n-queue-mode/docker-compose.yml.bak', 'docker-compose.yml.bak (config original)')
run_safe('cat /root/n8n-queue-mode/docker-compose.yml.bak2', 'docker-compose.yml.bak2')
run_safe('cat /root/n8n-queue-mode/.env 2>/dev/null | grep -v -iE "password|secret|key|token"', 'variables .env (sin secrets)')

# 2. Ver qué workflows tenía corriendo ese n8n (logs antes del apagado)
run_safe('docker logs --tail 50 n8n-queue-mode-n8n-1 2>&1 | head -60 || echo "contenedor ya no existe"', 'logs n8n-queue-mode (ultimos antes apagado)')

# 3. Versión instalada vs última disponible
run_safe('docker image inspect n8nio/n8n:2.1.4 --format "{{.RepoTags}} created={{.Created}}" 2>/dev/null || echo "imagen no en cache"', 'version n8n 2.1.4 en cache')
run_safe('docker image inspect n8nio/n8n:latest --format "{{.RepoTags}} created={{.Created}}" 2>/dev/null || echo "imagen latest no en cache"', 'version n8n latest en cache')

# 4. Cuántos workflows/executions tenía ese n8n en su DB propia
run_safe('docker run --rm -e POSTGRES_PASSWORD=password -v n8n-queue-mode_postgres-data:/var/lib/postgresql/data postgres:13 \
  psql -U postgres -d n8n_db -c "SELECT COUNT(*) as workflows FROM workflow_entity;" 2>/dev/null \
  || echo "no se puede consultar DB directamente"', 'workflows en DB de n8n-queue-mode')

# 5. Ver task runners — qué eran y por qué 2 corriendo al 100%
run_safe('cat /root/n8n-queue-mode/docker-compose.yml.bak | grep -A5 -i "task\\|runner\\|worker\\|CONCURRENCY\\|QUEUE"', 'config task runners y workers')

# 6. Ver si habia workflows pesados activos
run_safe('ls -la /root/n8n-queue-mode/n8n-data/ 2>/dev/null', 'n8n data dir')
run_safe('find /root/n8n-queue-mode/n8n-data -name "*.json" 2>/dev/null | head -10', 'archivos json en n8n-data')

# 7. Última versión disponible de n8n (via docker hub API)
run_safe('curl -s "https://registry.hub.docker.com/v2/repositories/n8nio/n8n/tags/?page_size=5&ordering=last_updated" \
  | python3 -c "import json,sys; data=json.load(sys.stdin); [print(t[\"name\"], t[\"last_updated\"][:10]) for t in data[\"results\"]]" \
  2>/dev/null || echo "no se pudo consultar docker hub"', 'ultimas versiones n8n en docker hub')

# 8. Gotenberg — qué version y config
run_safe('cat /root/n8n-queue-mode/docker-compose.yml.bak | grep -A20 gotenberg', 'config gotenberg en compose bak')
run_safe('docker image inspect gotenberg/gotenberg:8 --format "{{.RepoTags}} created={{.Created}}" 2>/dev/null', 'version gotenberg en cache')

client.close()
