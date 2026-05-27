import paramiko, json, urllib.request, urllib.error, ssl

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=15):
    print(f'\n--- {label or cmd[:70]} ---')
    _, stdout, stderr = client.exec_command(f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout)
    stdout.read(); stderr.read()
    sftp = client.open_sftp()
    try:
        with sftp.file('/tmp/out.txt', 'rb') as f:
            raw = f.read()
        safe = raw.decode('utf-8', errors='replace').encode('ascii', errors='replace').decode('ascii')
        print(safe[:3000] or '(sin output)')
        return safe
    finally:
        sftp.close()

# 1. Encontrar dominio de EasyPanel via Traefik config
print('=== BUSCANDO URL DE EASYPANEL ===')
run_safe('cat /etc/easypanel/traefik/config/main.yaml 2>/dev/null | grep -A5 -i "easypanel\\|panel" | head -30', 'traefik main config')
run_safe('cat /etc/easypanel/traefik/config/dashboard.yaml 2>/dev/null | head -40', 'traefik dashboard config')
run_safe('docker inspect easypanel.1.3qcdag24zhk0e87stdkfoqnq5 --format "{{json .Spec.TaskTemplate.ContainerSpec.Env}}" 2>/dev/null | python3 -m json.tool 2>/dev/null | grep -iE "domain|url|host" | head -10', 'env easypanel container')

# 2. Buscar credenciales admin en la DB de EasyPanel (LMDB)
run_safe('strings /etc/easypanel/data/data.mdb 2>/dev/null | grep -E "@|email|saburgos" | grep -v "^[a-z]" | head -20', 'buscar email en DB easypanel')

# 3. Ver si hay un archivo de configuracion con el dominio
run_safe('find /etc/easypanel -name "*.json" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs grep -l "domain\\|sixteam" 2>/dev/null | head -5', 'archivos con dominio sixteam')
run_safe('cat /etc/easypanel/traefik/config/main.yaml 2>/dev/null', 'traefik main.yaml completo')

client.close()

# 4. Probar conexión directa a EasyPanel via IP:3000
print('\n\n=== PROBANDO CONEXION A EASYPANEL API ===')
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

# Intentar health check
for url in [
    'https://72.60.67.214:3000/api/trpc/auth.login',
    'http://72.60.67.214:3000/api/trpc/auth.login',
]:
    try:
        req = urllib.request.Request(url, method='GET')
        with urllib.request.urlopen(req, timeout=5, context=ctx) as r:
            print(f'[OK] {url} -> {r.status}')
    except urllib.error.HTTPError as e:
        print(f'[HTTP {e.code}] {url}')
    except Exception as e:
        print(f'[ERR] {url} -> {type(e).__name__}: {str(e)[:60]}')
