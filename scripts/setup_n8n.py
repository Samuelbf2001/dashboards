#!/usr/bin/env python3
"""
1. Crea API key en n8n (via DB directa)
2. Recrea la credencial postgres-n8n-writer
3. Lista workflows existentes
4. Actualiza WF-03 y crea WF-14 via API
"""
import subprocess, json, uuid, secrets, sys

N8N       = 'https://n8ndash.sixteam.pro'
PG_CTR    = 'postgres_dashboard-postgres-1'
N8N_USER  = 'n8n_user'
N8N_DB    = 'n8n_internal'
GHL_KEY   = 'pit-6a8a2a21-4ec3-47c5-8096-5b5b80ad3351'

def psql_n8n(sql):
    r = subprocess.run(
        ['docker', 'exec', '-i', PG_CTR,
         'psql', '-U', N8N_USER, '-d', N8N_DB, '-t'],
        input=sql.encode(), capture_output=True, timeout=30
    )
    return r.stdout.decode().strip()

def curl_n8n(method, path, data=None, api_key=None):
    cmd = ['curl', '-s', '-X', method,
           '-H', 'Content-Type: application/json']
    if api_key:
        cmd += ['-H', f'X-N8N-API-KEY: {api_key}']
    if data:
        cmd += ['-d', json.dumps(data)]
    cmd.append(f'{N8N}{path}')
    r = subprocess.run(cmd, capture_output=True, timeout=30)
    raw = r.stdout.decode('utf-8', 'replace')
    try:
        return json.loads(raw)
    except Exception:
        return {'_raw': raw[:400]}

# ── 1. Obtener API key existente (o crear una nueva) ─────────────────────────
print('[1] Configurando API key de n8n...', flush=True)
uid = psql_n8n('SELECT id FROM "user" LIMIT 1;')
print(f'  User ID: {uid}')

# Intentar reusar clave existente
existing_key = psql_n8n('SELECT "apiKey" FROM user_api_keys LIMIT 1;')
if existing_key:
    api_key = existing_key
    print(f'  Reusando API key existente: {api_key[:20]}...')
else:
    key_id  = str(uuid.uuid4())
    api_key = 'n8n_api_' + secrets.token_hex(20)
    sql_key = (
        'INSERT INTO user_api_keys (id, "userId", label, "apiKey", "createdAt", "updatedAt") '
        f"VALUES ('{key_id}', '{uid}', 'sixteam', '{api_key}', NOW(), NOW()) "
        'ON CONFLICT DO NOTHING;'
    )
    psql_n8n(sql_key)
    print(f'  API Key nueva: {api_key}')

# Verificar
test = curl_n8n('GET', '/api/v1/workflows', api_key=api_key)
wf_count = len(test.get('data', []))
print(f'  Verificacion: {wf_count} workflows accesibles via API')
if '_raw' in test:
    print(f'  Raw response: {test["_raw"][:200]}')

# ── 2. Recrear credencial postgres-n8n-writer ────────────────────────────────
print('\n[2] Recreando credencial postgres-n8n-writer...', flush=True)

# Datos de la credencial (conecta al postgres del stack)
cred_data = {
    'name': 'Postgres n8n_writer',
    'type': 'postgres',
    'data': {
        'host': 'postgres',
        'port': 5432,
        'database': 'ghl_analytics',
        'user': 'n8n_writer',
        'password': 'CAMBIAR_POR_SECRET_MANAGER',
        'ssl': False,
        'allowUnauthorizedCerts': False
    }
}
cred_resp = curl_n8n('POST', '/api/v1/credentials', cred_data, api_key)
cred_id = cred_resp.get('id', '')
cred_name = cred_resp.get('name', '')
print(f'  Credencial creada: id={cred_id} name={cred_name}')
if '_raw' in cred_resp:
    print(f'  Raw: {cred_resp["_raw"]}')

# ── 3. Listar workflows actuales ─────────────────────────────────────────────
print('\n[3] Workflows existentes en n8n...', flush=True)
wf_list = curl_n8n('GET', '/api/v1/workflows', api_key=api_key)
workflows = wf_list.get('data', [])
wf_map = {}
for wf in workflows:
    name = wf.get('name', '')
    wfid = wf.get('id', '')
    wf_map[name] = wfid
    print(f'  [{wfid}] {name}')

# ── 4. Actualizar WF-03 y crear WF-14 ───────────────────────────────────────
print('\n[4] Importando workflows...', flush=True)

# Leer los JSONs del sistema de archivos
import os
wf_dir = '/etc/easypanel/projects/postgres/dashboard/code/n8n/workflows'

for fname, target_name in [
    ('WF-03_ghl_webhook_conversations.json', 'WF-03 GHL Webhook Conversations'),
    ('WF-14_polling_conversations.json',     'WF-14 Polling Conversations'),
]:
    fpath = os.path.join(wf_dir, fname)
    if not os.path.exists(fpath):
        print(f'  WARN: {fname} no encontrado en {wf_dir}')
        continue

    with open(fpath, 'r', encoding='utf-8') as f:
        wf_json = json.load(f)

    wf_json['name'] = target_name

    existing_id = wf_map.get(target_name, '')
    if existing_id:
        # Update
        resp = curl_n8n('PUT', f'/api/v1/workflows/{existing_id}', wf_json, api_key)
        action = 'actualizado'
    else:
        # Create
        resp = curl_n8n('POST', '/api/v1/workflows', wf_json, api_key)
        action = 'creado'

    rid = resp.get('id', resp.get('_raw', '')[:80])
    print(f'  {fname}: {action} (id={rid})')

print('\n[OK] Setup n8n completo.')
print(f'API_KEY={api_key}')
