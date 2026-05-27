import urllib.request, urllib.error, urllib.parse, json, ssl

EP_URL    = 'https://lbnkcu.easypanel.host'
API_TOKEN = '41cf2ab5c0f8dfffaa1eafdd86747592eb931e46adc10a71ed55b40285b9abd6'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def api(endpoint, params=None, payload=None, method='GET'):
    url = f'{EP_URL}/api/trpc/{endpoint}'
    if params:
        url += '?input=' + urllib.parse.quote(json.dumps({'json': params}))
    body = json.dumps({'json': payload}).encode() if payload else None
    req  = urllib.request.Request(url, data=body, method=method,
           headers={**({'Content-Type':'application/json'} if body else {}),
                    'Authorization': f'Bearer {API_TOKEN}'})
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {'error': e.code, 'body': e.read().decode()[:500]}
    except Exception as e:
        return {'error': str(e)}

# Intentar varios endpoints para ver servicios del proyecto postgres
endpoints_to_try = [
    ('projects.listProjects', None),
    ('services.listServices', {'projectName': 'postgres'}),
    ('services.getServices',  {'projectName': 'postgres'}),
    ('apps.listApps',         {'projectName': 'postgres'}),
]

for ep, params in endpoints_to_try:
    r = api(ep, params=params)
    if 'error' not in r:
        print(f'\n[OK] {ep}:')
        print(json.dumps(r, indent=2, default=str)[:2000])
    else:
        print(f'[x]  {ep}: {r.get("error")} {r.get("body","")[:80]}')

# Buscar directamente el servicio n8n dentro del proyecto postgres
print('\n\n=== Buscando n8n en proyecto postgres ===')
r = api('apps.getApp', params={'projectName': 'postgres', 'serviceName': 'n8n'})
print(json.dumps(r, indent=2, default=str)[:2000])

print('\n=== Buscando gotenberg ===')
r2 = api('apps.getApp', params={'projectName': 'postgres', 'serviceName': 'gotenberg'})
print(json.dumps(r2, indent=2, default=str)[:2000])
