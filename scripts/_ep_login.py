import urllib.request, urllib.error, json, ssl

EP_URL = 'https://lbnkcu.easypanel.host'
EMAIL  = 'saburgosf@gmail.com'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def trpc_post(endpoint, payload, token=None):
    url  = f'{EP_URL}/api/trpc/{endpoint}'
    body = json.dumps({'json': payload}).encode()
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(url, data=body, headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='replace')
        return {'error': e.code, 'body': body[:500]}
    except Exception as e:
        return {'error': str(e)}

def trpc_get(endpoint, token=None):
    url  = f'{EP_URL}/api/trpc/{endpoint}'
    headers = {}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(url, headers=headers, method='GET')
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='replace')
        return {'error': e.code, 'body': body[:500]}
    except Exception as e:
        return {'error': str(e)}

# Intentar login con passwords conocidos
passwords = ['3002408743S', 'elsamu10', 'Sixteam2026-']
session_token = None

for pwd in passwords:
    print(f'\nProbando login con password: {"*"*len(pwd)}...')
    result = trpc_post('auth.login', {'email': EMAIL, 'password': pwd})
    if 'error' not in result or result.get('error') != 401:
        print(f'Respuesta: {json.dumps(result)[:300]}')
        # Extraer token si viene en result
        try:
            token = result['result']['data']['json']['token']
            session_token = token
            print(f'TOKEN OBTENIDO: {token[:30]}...')
            break
        except (KeyError, TypeError):
            print(f'Respuesta sin token esperado: {str(result)[:200]}')
    else:
        print(f'  -> Fallido ({result})')

if session_token:
    print('\n\n=== OBTENIENDO USUARIO ID ===')
    users = trpc_get('users.listUsers', token=session_token)
    print(json.dumps(users)[:1000])

    # Extraer user ID
    try:
        user_list = users['result']['data']['json']
        my_user = next(u for u in user_list if u.get('email') == EMAIL)
        user_id = my_user['id']
        print(f'\nMi user ID: {user_id}')

        print('\n=== GENERANDO API TOKEN PERMANENTE ===')
        gen = trpc_post('users.generateApiToken', {'id': user_id}, token=session_token)
        print(json.dumps(gen)[:500])

        print('\n=== VERIFICANDO API TOKEN ===')
        users2 = trpc_get('users.listUsers', token=session_token)
        my_user2 = next(u for u in users2['result']['data']['json'] if u.get('email') == EMAIL)
        api_token = my_user2.get('apiToken', 'NO ENCONTRADO')
        print(f'\nAPI TOKEN PERMANENTE: {api_token}')

        print('\n=== LISTANDO PROYECTOS ===')
        projects = trpc_get('projects.listProjects', token=api_token)
        print(json.dumps(projects)[:2000])

    except Exception as e:
        print(f'Error parseando: {e}')
        print(json.dumps(users)[:500])
else:
    print('\n\nNo se pudo obtener token. Necesito la password de EasyPanel.')
