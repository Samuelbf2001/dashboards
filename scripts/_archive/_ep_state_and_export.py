import urllib.request
import urllib.error
import urllib.parse
import json, ssl, paramiko, time

EP_URL    = 'https://lbnkcu.easypanel.host'
API_TOKEN = '41cf2ab5c0f8dfffaa1eafdd86747592eb931e46adc10a71ed55b40285b9abd6'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def trpc_get(endpoint, params=None):
    url = f'{EP_URL}/api/trpc/{endpoint}'
    if params:
        url += '?input=' + urllib.parse.quote(json.dumps({'json': params}))
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {API_TOKEN}'})
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {'error': e.code, 'body': e.read().decode()[:400]}
    except Exception as e:
        return {'error': str(e)}

# ── 1. Ver todos los proyectos y servicios en EasyPanel ──────────────
print('='*60)
print('  ESTADO ACTUAL EN EASYPANEL')
print('='*60)
raw = trpc_get('projects.listProjects')
try:
    projects = raw['result']['data']['json']
    for p in projects:
        print(f"\nProyecto: {p['name']}")
        for svc in p.get('services', []):
            status = svc.get('deploymentStatus','?')
            stype  = svc.get('type','?')
            doms   = [d.get('host','') for d in svc.get('domains',[])]
            image  = svc.get('image','')
            print(f"  [{stype}] {svc['name']:25s} status={status:15s} {' '.join(doms)} {image}")
except Exception as e:
    print(f'Error: {e} | raw: {str(raw)[:300]}')

# ── 2. Exportar workflows del postgres viejo via SSH ─────────────────
print('\n\n' + '='*60)
print('  EXPORTANDO WORKFLOWS DEL N8N VIEJO')
print('='*60)

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('72.60.67.214', username='root', password='Sixteam2026-', timeout=15)

def run_safe(cmd, label='', timeout=40):
    print(f'\n--- {label or cmd[:70]} ---')
    _, stdout, stderr = ssh.exec_command(f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout)
    stdout.read(); stderr.read()
    sftp = ssh.open_sftp()
    try:
        with sftp.file('/tmp/out.txt','rb') as f:
            raw = f.read()
        safe = raw.decode('utf-8', errors='replace').encode('ascii', errors='replace').decode('ascii')
        print(safe[:4000] or '(sin output)')
        return raw.decode('utf-8', errors='replace')
    finally:
        sftp.close()

# Levantar postgres temporal y exportar workflows como JSON
script = r"""#!/bin/bash
LOG=/tmp/export.log
echo "=== $(date) ===" > $LOG

docker run -d --name n8n_export_pg \
  -e POSTGRES_USER=n8n_user \
  -e POSTGRES_PASSWORD=elsamu10 \
  -e POSTGRES_DB=n8n_db \
  -v /root/n8n-queue-mode/postgres-data:/var/lib/postgresql/data \
  postgres:13 >> $LOG 2>&1

sleep 12

# Exportar workflows como JSON (id, name, nodes, connections, active, settings)
docker exec n8n_export_pg psql -U n8n_user -d n8n_db -t -A \
  -c "SELECT json_build_object(
        'id', id,
        'name', name,
        'active', active,
        'nodes', nodes::json,
        'connections', connections::json,
        'settings', settings::json,
        'updatedAt', \"updatedAt\"
      )
      FROM workflow_entity
      WHERE active = true
      ORDER BY \"updatedAt\" DESC;" \
  > /tmp/workflows_export.json 2>>$LOG

echo "--- Contenido export ---" >> $LOG
wc -l /tmp/workflows_export.json >> $LOG
echo "OK" >> $LOG

# Ver webhooks / triggers de los workflows activos
echo "--- Webhooks en workflows ---" >> $LOG
docker exec n8n_export_pg psql -U n8n_user -d n8n_db -t \
  -c "SELECT we.name, n.value->>'type' as node_type, n.value->>'webhookId' as webhook_id, n.value->'parameters'->>'path' as path
      FROM workflow_entity we,
      jsonb_array_elements(we.nodes::jsonb) n
      WHERE we.active = true
      AND (n.value->>'type' LIKE '%webhook%' OR n.value->>'type' LIKE '%trigger%')
      ORDER BY we.name;" >> $LOG 2>&1

docker stop n8n_export_pg >> $LOG 2>&1
docker rm n8n_export_pg >> $LOG 2>&1
echo "=== FIN $(date) ===" >> $LOG
"""

sftp2 = ssh.open_sftp()
with sftp2.file('/tmp/export_wf.sh','w') as f:
    f.write(script)
sftp2.chmod('/tmp/export_wf.sh', 0o755)
sftp2.close()

ssh.exec_command('bash /tmp/export_wf.sh > /tmp/export_main.log 2>&1 &')
print('Exportando workflows... esperando 25s')
time.sleep(25)

run_safe('cat /tmp/export.log', 'log de exportación')

# Leer el JSON exportado
print('\n--- Workflows exportados ---')
sftp3 = ssh.open_sftp()
try:
    with sftp3.file('/tmp/workflows_export.json','rb') as f:
        wf_raw = f.read().decode('utf-8', errors='replace')
    # Parsear línea por línea (psql -t -A devuelve una fila por línea)
    workflows = []
    for line in wf_raw.strip().split('\n'):
        line = line.strip()
        if line and line.startswith('{'):
            try:
                wf = json.loads(line)
                workflows.append(wf)
                print(f"\nWorkflow: {wf['name']} (active={wf['active']})")
                # Buscar nodos webhook/trigger
                for node in wf.get('nodes', []):
                    ntype = node.get('type','')
                    if 'webhook' in ntype.lower() or 'trigger' in ntype.lower():
                        params = node.get('parameters', {})
                        print(f"  Trigger: {ntype}")
                        print(f"    path: {params.get('path','')}")
                        print(f"    webhookId: {node.get('webhookId','')}")
                        print(f"    httpMethod: {params.get('httpMethod','')}")
            except json.JSONDecodeError as e:
                print(f'  [parse error: {e}] {line[:100]}')

    # Guardar localmente
    output_path = 'c:/Users/Lenovo/Desktop/dASHBOARD/dashboards/scripts/workflows_export.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(workflows, f, indent=2, ensure_ascii=False, default=str)
    print(f'\n✓ {len(workflows)} workflows guardados en workflows_export.json')
finally:
    sftp3.close()

ssh.close()
