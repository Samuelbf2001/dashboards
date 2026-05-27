import urllib.request, urllib.error, urllib.parse, json, ssl

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

# Ver todos los proyectos con sus servicios en detalle
raw = trpc_get('projects.listProjects')
try:
    projects = raw['result']['data']['json']
    for p in projects:
        print(f"\n{'='*60}")
        print(f"  PROYECTO: {p['name']}")
        print('='*60)
        svcs = p.get('services', [])
        if not svcs:
            print('  (sin servicios visibles en listado)')
        for svc in svcs:
            print(f"\n  Servicio: {svc['name']}")
            print(f"    type:   {svc.get('type','?')}")
            print(f"    status: {svc.get('deploymentStatus','?')}")
            print(f"    image:  {svc.get('image','')}")
            doms = svc.get('domains', [])
            for d in doms:
                print(f"    domain: {d.get('host','')}  path={d.get('path','/')}")
            env = svc.get('env','')
            if env:
                # Mostrar env sin secrets
                safe_lines = []
                for line in env.split('\n'):
                    if any(k in line.upper() for k in ['PASS','SECRET','KEY','TOKEN']):
                        parts = line.split('=',1)
                        safe_lines.append(f"{parts[0]}=***")
                    else:
                        safe_lines.append(line)
                print(f"    env:\n      " + '\n      '.join(safe_lines[:20]))
except Exception as e:
    print(f'Error: {e}')
    print(json.dumps(raw, indent=2)[:2000])

# Ver detalle específico del proyecto postgres
print('\n\n' + '='*60)
print('  DETALLE PROYECTO postgres (getProject)')
print('='*60)
detail = trpc_get('projects.getProject', {'projectName': 'postgres'})
try:
    proj = detail['result']['data']['json']
    svcs = proj.get('services', [])
    print(f"Total servicios: {len(svcs)}")
    for svc in svcs:
        print(f"\n  {svc['name']} [{svc.get('type','?')}] status={svc.get('deploymentStatus','?')}")
        env = svc.get('env','')
        if env:
            for line in env.split('\n'):
                if line.strip():
                    if any(k in line.upper() for k in ['PASS','SECRET','KEY','TOKEN']):
                        parts = line.split('=',1)
                        print(f"    {parts[0]}=***")
                    else:
                        print(f"    {line}")
        doms = svc.get('domains', [])
        for d in doms:
            print(f"    domain: {d.get('host','')}  path={d.get('path','/')}")
except Exception as e:
    print(f'Error: {e}')
    print(str(detail)[:1000])
