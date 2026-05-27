"""
Agrega nodo "Escribir Custom Fields" a WF-01 y WF-02 como rama paralela.
Los 3 nodos de escritura (INSERT, SCD2 INSERT, UPDATE MINOR) disparan el CF writer
en paralelo — no bloquea la respuesta al webhook.
"""
import json, sys, os

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ROOT = os.path.join(os.path.dirname(__file__), '..', 'n8n', 'workflows')

# ── SQL para fact_contact_custom_fields ───────────────────────────────────────
SQL_CONTACT = (
    "INSERT INTO fact_contact_custom_fields\n"
    "  (contact_id, location_id, field_id, value_text, value_number, value_date, updated_at)\n"
    "SELECT\n"
    "  $1, $2,\n"
    "  cf->>'id',\n"
    "  CASE WHEN (cf->>'value') !~ '^\\d{4}-\\d{2}-\\d{2}'\n"
    "            AND (cf->>'value') !~ '^-?\\d+(\\.\\d+)?$'\n"
    "       THEN cf->>'value' END,\n"
    "  CASE WHEN (cf->>'value') ~ '^-?\\d+(\\.\\d+)?$'\n"
    "       THEN (cf->>'value')::NUMERIC END,\n"
    "  CASE WHEN (cf->>'value') ~ '^\\d{4}-\\d{2}-\\d{2}'\n"
    "       THEN (substring(cf->>'value', 1, 10))::DATE END,\n"
    "  NOW()\n"
    "FROM jsonb_array_elements(COALESCE($3::jsonb, '[]'::jsonb)) cf\n"
    "JOIN ghl_field_whitelist w\n"
    "  ON  w.location_id = $2\n"
    "  AND w.field_id    = cf->>'id'\n"
    "  AND w.entity_type = 'contact'\n"
    "  AND w.active      = TRUE\n"
    "WHERE cf->>'id' IS NOT NULL\n"
    "  AND cf->>'value' IS NOT NULL\n"
    "  AND cf->>'value' <> ''\n"
    "ON CONFLICT (contact_id, field_id) DO UPDATE SET\n"
    "  value_text   = EXCLUDED.value_text,\n"
    "  value_number = EXCLUDED.value_number,\n"
    "  value_date   = EXCLUDED.value_date,\n"
    "  updated_at   = NOW()"
)

SQL_OPP = SQL_CONTACT.replace(
    'fact_contact_custom_fields', 'fact_opp_custom_fields'
).replace(
    '(contact_id, location_id,', '(opportunity_id, location_id,'
).replace(
    'ON CONFLICT (contact_id,', 'ON CONFLICT (opportunity_id,'
).replace(
    "w.entity_type = 'contact'", "w.entity_type = 'opportunity'"
)

PARAMS_CONTACT = (
    "={{ [ $json.record.contact_id, $json.record.location_id,"
    " JSON.stringify($json.record.custom_fields) ] }}"
)
PARAMS_OPP = (
    "={{ [ $json.record.opportunity_id, $json.record.location_id,"
    " JSON.stringify($json.record.custom_fields) ] }}"
)

CREDS = {"postgres": {"id": "postgres-n8n-writer", "name": "Postgres n8n_writer"}}


def make_cf_node(node_id, name, sql, params, position):
    return {
        "id": node_id,
        "name": name,
        "type": "n8n-nodes-base.postgres",
        "typeVersion": 2.5,
        "position": position,
        "parameters": {
            "operation": "executeQuery",
            "query": sql,
            "additionalFields": {"queryParams": params}
        },
        "credentials": CREDS
    }


def add_parallel_connection(connections, from_node, to_node):
    """Agrega una conexión paralela de from_node → to_node sin quitar las existentes."""
    if from_node not in connections:
        connections[from_node] = {"main": [[]]}
    if not connections[from_node].get("main"):
        connections[from_node]["main"] = [[]]
    if not connections[from_node]["main"][0]:
        connections[from_node]["main"][0] = []
    # Avoid duplicates
    existing = [c["node"] for c in connections[from_node]["main"][0]]
    if to_node not in existing:
        connections[from_node]["main"][0].append({"node": to_node, "type": "main", "index": 0})


def patch_wf01():
    path = os.path.join(ROOT, 'WF-01_ghl_webhook_contacts.json')
    wf = json.load(open(path, encoding='utf-8'))

    cf_node = make_cf_node(
        "node-cf-contacts",
        "Escribir Custom Fields Contacto",
        SQL_CONTACT, PARAMS_CONTACT,
        [2000, 500]
    )

    # Reemplazar si ya existe (para actualizar el SQL), agregar si no
    existing_names = [n['name'] for n in wf['nodes']]
    if cf_node['name'] in existing_names:
        wf['nodes'] = [cf_node if n['name'] == cf_node['name'] else n for n in wf['nodes']]
    else:
        wf['nodes'].append(cf_node)

    conns = wf.setdefault('connections', {})
    for src in ['INSERT dim_contacts', 'SCD2 INSERT Nueva Version', 'UPDATE MINOR dim_contacts']:
        add_parallel_connection(conns, src, cf_node['name'])

    json.dump(wf, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(f'[OK] WF-01 actualizado — nodo: "{cf_node["name"]}"')


def patch_wf02():
    path = os.path.join(ROOT, 'WF-02_ghl_webhook_opportunities.json')
    wf = json.load(open(path, encoding='utf-8'))

    cf_node = make_cf_node(
        "node-cf-opps",
        "Escribir Custom Fields Oportunidad",
        SQL_OPP, PARAMS_OPP,
        [2000, 700]
    )

    existing_names = [n['name'] for n in wf['nodes']]
    if cf_node['name'] in existing_names:
        wf['nodes'] = [cf_node if n['name'] == cf_node['name'] else n for n in wf['nodes']]
    else:
        wf['nodes'].append(cf_node)

    conns = wf.setdefault('connections', {})
    for src in ['INSERT dim_opportunities',
                'SCD2 INSERT Nueva Version Opp',
                'UPDATE MINOR dim_opportunities']:
        add_parallel_connection(conns, src, cf_node['name'])

    json.dump(wf, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(f'[OK] WF-02 actualizado — nodo: "{cf_node["name"]}"')


if __name__ == '__main__':
    patch_wf01()
    patch_wf02()
    print('\nListo. Importa los workflows actualizados en n8n para activar.')
