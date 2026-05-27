"""
Agrega soporte multi-location a WF-01..04:
  1. Webhook path: ghl/contacts → ghl/contacts/:location_id
  2. Sanitizadores leen location_id del path param primero, payload segundo
  3. Nuevo nodo "Verificar Location" (Postgres SELECT COUNT)
  4. Nuevo nodo "Location Activa?" (IF) → bypass 200 si location no registrada
"""
import json, sys, os

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ROOT = os.path.join(os.path.dirname(__file__), '..', 'n8n', 'workflows')
CREDS = {"postgres": {"id": "postgres-n8n-writer", "name": "Postgres n8n_writer"}}

# ── nodos nuevos ──────────────────────────────────────────────────────────────

def make_verify_location_node(node_id, pos):
    return {
        "id": node_id,
        "name": "Verificar Location",
        "type": "n8n-nodes-base.postgres",
        "typeVersion": 2.5,
        "position": pos,
        "parameters": {
            "operation": "executeQuery",
            "query": (
                "SELECT COUNT(*) AS cnt\n"
                "FROM ghl_locations\n"
                "WHERE location_id = $1\n"
                "  AND active = TRUE"
            ),
            "additionalFields": {
                "queryParams": "={{ [$json.record.location_id] }}"
            }
        },
        "credentials": CREDS
    }

def make_location_active_node(node_id, pos):
    return {
        "id": node_id,
        "name": "Location Activa?",
        "type": "n8n-nodes-base.if",
        "position": pos,
        "parameters": {
            "conditions": {
                "number": [{
                    "value1": "={{ $json.cnt }}",
                    "operation": "larger",
                    "value2": 0
                }],
                "combinator": "and",
                "options": {}
            },
            "options": {}
        }
    }

# ── helpers de conexiones ─────────────────────────────────────────────────────

def get_first_downstream(conns, from_node, branch=0):
    """Devuelve el primer nodo al que 'from_node' conecta en la rama branch."""
    targets = conns.get(from_node, {}).get("main", [])
    if branch < len(targets) and targets[branch]:
        return targets[branch][0]["node"]
    return None

def set_connection(conns, from_node, branch, to_node):
    """Reemplaza (o crea) la única conexión de from_node en la rama branch."""
    if from_node not in conns:
        conns[from_node] = {"main": [[]]}
    while len(conns[from_node]["main"]) <= branch:
        conns[from_node]["main"].append([])
    conns[from_node]["main"][branch] = [{"node": to_node, "type": "main", "index": 0}]

def add_parallel_conn(conns, from_node, to_node, branch=0):
    """Agrega conexión paralela sin quitar existentes."""
    if from_node not in conns:
        conns[from_node] = {"main": [[]]}
    while len(conns[from_node]["main"]) <= branch:
        conns[from_node]["main"].append([])
    existing = [c["node"] for c in conns[from_node]["main"][branch]]
    if to_node not in existing:
        conns[from_node]["main"][branch].append({"node": to_node, "type": "main", "index": 0})

# ── actualizar código sanitizador ─────────────────────────────────────────────
# Cada sanitizador tiene ligeras variaciones en el patrón de extracción.

REPLACEMENTS = [
    # WF-01: 2 líneas con `?` al inicio de la segunda
    (
        "const location_id = REGEX_LOCATION_ID.test(String(body.locationId || '').trim())\n"
        "  ? String(body.locationId).trim() : null;",
        "const _loc_raw = (raw.params && raw.params.location_id)\n"
        "  ? raw.params.location_id\n"
        "  : (body.locationId || '');\n"
        "const location_id = REGEX_LOCATION_ID.test(String(_loc_raw).trim())\n"
        "  ? String(_loc_raw).trim() : null;"
    ),
    # WF-03 "Sanitizar Conversacion": 5 espacios entre nombre y =
    (
        "const location_id     = REGEX_LOCATION_ID.test(String(body.locationId || '').trim())"
        " ? String(body.locationId).trim() : null;",
        "const _loc_raw = (raw.params && raw.params.location_id)\n"
        "  ? raw.params.location_id\n"
        "  : (body.locationId || '');\n"
        "const location_id     = REGEX_LOCATION_ID.test(String(_loc_raw).trim())"
        " ? String(_loc_raw).trim() : null;"
    ),
    # WF-04 "Sanitizar Cita": 4 espacios entre nombre y =
    (
        "const location_id    = REGEX_LOCATION_ID.test(String(body.locationId || '').trim())"
        " ? String(body.locationId).trim() : null;",
        "const _loc_raw = (raw.params && raw.params.location_id)\n"
        "  ? raw.params.location_id\n"
        "  : (body.locationId || '');\n"
        "const location_id    = REGEX_LOCATION_ID.test(String(_loc_raw).trim())"
        " ? String(_loc_raw).trim() : null;"
    ),
    # WF-02 "Sanitizar Oportunidad": usa variable rawLocationId intermedia
    (
        "const rawLocationId = body.locationId || (body.location && body.location.id) || '';",
        "const rawLocationId = (raw.params && raw.params.location_id)\n"
        "  ? raw.params.location_id\n"
        "  : (body.locationId || (body.location && body.location.id) || '');"
    ),
]

def patch_sanitizer(wf, sanitizer_name):
    for node in wf['nodes']:
        if node['name'] == sanitizer_name:
            code = node['parameters'].get('jsCode', '')
            if 'raw.params' in code:
                print(f'  [SKIP] {sanitizer_name} ya tiene params.location_id')
                return
            patched = False
            for old, new in REPLACEMENTS:
                if old in code:
                    node['parameters']['jsCode'] = code.replace(old, new)
                    print(f'  [OK]  {sanitizer_name}: location_id ahora prefiere URL path param')
                    patched = True
                    break
            if not patched:
                print(f'  [WARN] {sanitizer_name}: patrón location_id no encontrado, revisar manualmente')
            return

# ── lógica principal ──────────────────────────────────────────────────────────

def patch_workflow(fname, webhook_node_name, sanitizer_name, verify_id, active_id):
    path = os.path.join(ROOT, fname)
    wf = json.load(open(path, encoding='utf-8'))

    print(f'\n=== {fname} ===')

    # 1. Actualizar path del webhook
    for node in wf['nodes']:
        if node['name'] == webhook_node_name:
            old_path = node['parameters'].get('path', '')
            if ':location_id' in old_path:
                print(f'  [SKIP] webhook path ya tiene :location_id')
            else:
                node['parameters']['path'] = old_path + '/:location_id'
                print(f'  [OK]  webhook path: {old_path} → {node["parameters"]["path"]}')
            break

    # 2. Actualizar sanitizador
    patch_sanitizer(wf, sanitizer_name)

    # 3. Obtener posición del sanitizador
    san_pos = next(
        (n['position'] for n in wf['nodes'] if n['name'] == sanitizer_name),
        [1200, 300]
    )
    verify_pos  = [san_pos[0] + 300, san_pos[1]]
    active_pos  = [san_pos[0] + 600, san_pos[1]]

    # 4. Agregar nodos si no existen
    existing = {n['name'] for n in wf['nodes']}

    if 'Verificar Location' not in existing:
        wf['nodes'].append(make_verify_location_node(verify_id, verify_pos))
        print(f'  [OK]  nodo "Verificar Location" agregado')
    else:
        print(f'  [SKIP] "Verificar Location" ya existe')

    if 'Location Activa?' not in existing:
        wf['nodes'].append(make_location_active_node(active_id, active_pos))
        print(f'  [OK]  nodo "Location Activa?" agregado')
    else:
        print(f'  [SKIP] "Location Activa?" ya existe')

    # 5. Rewire conexiones
    conns = wf.setdefault('connections', {})

    # Nodo al que sanitizador conecta actualmente (irá al true-branch del IF)
    first_proc = get_first_downstream(conns, sanitizer_name, branch=0)

    # Sanitizador → Verificar Location
    set_connection(conns, sanitizer_name, 0, 'Verificar Location')

    # Verificar Location → Location Activa?
    set_connection(conns, 'Verificar Location', 0, 'Location Activa?')

    # Location Activa? → [0] first_proc, [1] Responder 200 OK
    if first_proc and first_proc not in ('Verificar Location', 'Location Activa?'):
        set_connection(conns, 'Location Activa?', 0, first_proc)
        print(f'  [OK]  Location Activa?[true] → {first_proc}')
    else:
        print(f'  [WARN] first_proc no determinado: {first_proc}')

    # False branch → Responder 200 OK
    set_connection(conns, 'Location Activa?', 1, 'Responder 200 OK')
    print(f'  [OK]  Location Activa?[false] → Responder 200 OK (skip silencioso)')

    json.dump(wf, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(f'  [SAVED] {fname}')


if __name__ == '__main__':
    patch_workflow(
        'WF-01_ghl_webhook_contacts.json',
        'Webhook GHL Contactos', 'Sanitizar Contacto',
        'node-verify-loc-01', 'node-loc-active-01'
    )
    patch_workflow(
        'WF-02_ghl_webhook_opportunities.json',
        'Webhook GHL Oportunidades', 'Sanitizar Oportunidad',
        'node-verify-loc-02', 'node-loc-active-02'
    )
    patch_workflow(
        'WF-03_ghl_webhook_conversations.json',
        'Webhook GHL Conversaciones', 'Sanitizar Conversacion',
        'node-verify-loc-03', 'node-loc-active-03'
    )
    patch_workflow(
        'WF-04_ghl_webhook_appointments.json',
        'Webhook GHL Citas', 'Sanitizar Cita',
        'node-verify-loc-04', 'node-loc-active-04'
    )

    print('\n[DONE] Importa los workflows actualizados en n8n.')
    print('       Actualiza los webhook URLs en GHL por location:')
    print('  https://n8ndash.sixteam.pro/webhook/ghl/contacts/<LOCATION_ID>')
    print('  https://n8ndash.sixteam.pro/webhook/ghl/opportunities/<LOCATION_ID>')
    print('  https://n8ndash.sixteam.pro/webhook/ghl/conversations/<LOCATION_ID>')
    print('  https://n8ndash.sixteam.pro/webhook/ghl/appointments/<LOCATION_ID>')
