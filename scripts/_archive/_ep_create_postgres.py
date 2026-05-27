import urllib.request, urllib.error, urllib.parse, json, ssl

EP_URL    = 'https://lbnkcu.easypanel.host'
API_TOKEN = '41cf2ab5c0f8dfffaa1eafdd86747592eb931e46adc10a71ed55b40285b9abd6'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def api(endpoint, payload=None, params=None, method=None):
    url = f'{EP_URL}/api/trpc/{endpoint}'
    if params:
        url += '?input=' + urllib.parse.quote(json.dumps({'json': params}))
    body = json.dumps({'json': payload}).encode() if payload is not None else None
    m = method or ('POST' if body else 'GET')
    req = urllib.request.Request(url, data=body, method=m,
          headers={**({'Content-Type':'application/json'} if body else {}),
                   'Authorization': f'Bearer {API_TOKEN}'})
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {'error': e.code, 'body': e.read().decode()[:500]}
    except Exception as e:
        return {'error': str(e)}

def try_ep(label, endpoint, payload=None, params=None):
    r = api(endpoint, payload=payload, params=params)
    if 'error' not in r:
        print(f'[OK] {label}:\n{json.dumps(r, indent=2, default=str)[:1000]}')
        return r
    else:
        code = r.get('error','?')
        body = r.get('body','')
        if '404' in str(code) and 'NOT_FOUND' in body:
            print(f'[ ] {label}: endpoint no existe')
        else:
            print(f'[!] {label}: {code} — {body[:120]}')
        return None

PROJECT = 'postgres'
SVC     = 'n8n-db'

print('=== BUSCANDO ENDPOINT CORRECTO PARA CREAR POSTGRES EN EASYPANEL ===\n')

# Intentar múltiples variantes de endpoint que EasyPanel podría usar
candidates = [
    ('postgres.createService',   {'projectName': PROJECT, 'serviceName': SVC}),
    ('postgres.create',          {'projectName': PROJECT, 'name': SVC}),
    ('services.createPostgres',  {'projectName': PROJECT, 'serviceName': SVC}),
    ('database.create',          {'projectName': PROJECT, 'serviceName': SVC, 'type': 'postgres'}),
    ('databases.create',         {'projectName': PROJECT, 'serviceName': SVC, 'type': 'postgres'}),
    ('app.createPostgres',       {'projectName': PROJECT, 'serviceName': SVC}),
    ('projects.createPostgres',  {'projectName': PROJECT, 'serviceName': SVC}),
]

found_endpoint = None
for label, payload in candidates:
    r = try_ep(label, label, payload=payload)
    if r and 'error' not in r:
        found_endpoint = (label, payload)
        break

if not found_endpoint:
    print('\n=== DESCUBRIENDO ENDPOINTS VIA BATCH ===')
    # tRPC batch request para probar múltiples a la vez
    batch_url = f'{EP_URL}/api/trpc/postgres.createService,postgres.create,services.createPostgres?batch=1'
    req = urllib.request.Request(batch_url,
          headers={'Authorization': f'Bearer {API_TOKEN}'})
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            print(f'Batch response: {r.read().decode()[:500]}')
    except urllib.error.HTTPError as e:
        print(f'Batch HTTP {e.code}: {e.read().decode()[:300]}')
    except Exception as e:
        print(f'Batch error: {e}')

    # Intentar inferir endpoints desde el panel mismo
    print('\n=== EXPLORANDO ENDPOINTS CONOCIDOS ===')
    known = [
        ('GET', 'projects.listProjects', None),
        ('GET', 'users.listUsers',       None),
        # Intentar con nombres de servicio de easypanel
        ('POST', 'postgres.createService', {'projectName': PROJECT, 'serviceName': SVC, 'image': 'postgres:16', 'password': 'n8npdf2026'}),
        ('POST', 'services.create', {'projectName': PROJECT, 'serviceName': SVC, 'type': 'postgres'}),
        ('POST', 'app.createApp', {'projectName': PROJECT, 'serviceName': SVC}),
    ]
    for method, ep, payload in known:
        r = api(ep, payload=payload, method=method if method=='POST' else None)
        code = r.get('error', 'OK')
        body = r.get('body', str(r)[:100])
        print(f'  [{method}] {ep}: {code} | {body[:80]}')
