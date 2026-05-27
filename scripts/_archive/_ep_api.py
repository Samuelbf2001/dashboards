import urllib.request, urllib.error, json, ssl

EP_URL   = 'https://lbnkcu.easypanel.host'
API_TOKEN = '41cf2ab5c0f8dfffaa1eafdd86747592eb931e46adc10a71ed55b40285b9abd6'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def trpc_get(endpoint, params=None):
    url = f'{EP_URL}/api/trpc/{endpoint}'
    if params:
        import urllib.parse
        url += '?input=' + urllib.parse.quote(json.dumps({'json': params}))
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {API_TOKEN}'})
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {'error': e.code, 'body': e.read().decode('utf-8', errors='replace')[:300]}
    except Exception as e:
        return {'error': str(e)}

def trpc_post(endpoint, payload):
    url  = f'{EP_URL}/api/trpc/{endpoint}'
    body = json.dumps({'json': payload}).encode()
    req  = urllib.request.Request(url, data=body,
           headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {API_TOKEN}'},
           method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {'error': e.code, 'body': e.read().decode('utf-8', errors='replace')[:300]}
    except Exception as e:
        return {'error': str(e)}

def show(label, data, indent=2):
    print(f'\n{"="*60}')
    print(f'  {label}')
    print('='*60)
    print(json.dumps(data, indent=indent, default=str)[:4000])

# 1. Listar proyectos
projects_raw = trpc_get('projects.listProjects')
try:
    projects = projects_raw['result']['data']['json']
    print('\n=== PROYECTOS EN EASYPANEL ===')
    for p in projects:
        print(f"\n  Proyecto: {p['name']}")
        for svc in p.get('services', []):
            status = svc.get('deploymentStatus', '?')
            stype  = svc.get('type', '?')
            domain = ''
            doms   = svc.get('domains', [])
            if doms:
                domain = doms[0].get('host', '')
            print(f"    [{stype}] {svc['name']}  status={status}  domain={domain}")
except Exception as e:
    print(f'Error: {e}')
    show('RAW projects', projects_raw)

# 2. Detalle del proyecto postgres (el nuestro)
print('\n\n=== DETALLE PROYECTO: postgres ===')
detail = trpc_get('projects.getProject', {'projectName': 'postgres'})
try:
    proj = detail['result']['data']['json']
    for svc in proj.get('services', []):
        name   = svc['name']
        stype  = svc.get('type', '?')
        status = svc.get('deploymentStatus', '?')
        image  = svc.get('image', '')
        doms   = [d.get('host','') for d in svc.get('domains', [])]
        print(f"\n  {name} ({stype}) [{status}]")
        if image: print(f"    image: {image}")
        if doms:  print(f"    domains: {doms}")
except Exception as e:
    print(f'Error: {e}')
    show('RAW detail', detail)

# Guardar el token para los siguientes scripts
with open('c:/Users/Lenovo/Desktop/dASHBOARD/dashboards/scripts/_ep_token.txt', 'w') as f:
    f.write(API_TOKEN)
print(f'\n\nAPI Token guardado en _ep_token.txt')
print(f'EasyPanel URL: {EP_URL}')
