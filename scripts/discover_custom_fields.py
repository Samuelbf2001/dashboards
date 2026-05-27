"""
Descubre los custom fields de una location GHL y los agrupa por entidad
(contact / opportunity). Imprime una tabla CSV-style en stdout para que
elijas cuáles promover a canonicals.

Uso:
  python discover_custom_fields.py <location_id>

Si no se pasa location_id usa el de milotecucuta por defecto.
"""
import sys
import json
import urllib.request
import urllib.error

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

GHL_API_BASE = 'https://services.leadconnectorhq.com'
GHL_TOKEN    = 'pit-6a8a2a21-4ec3-47c5-8096-5b5b80ad3351'
GHL_VERSION  = '2021-07-28'

DEFAULT_LOCATION = '0IP2MEmSx0fpdVllDK5b'   # milotecucuta


def fetch_custom_fields(location_id, model=None):
    """
    GET /locations/{id}/customFields  o  ?model=contact|opportunity
    Devuelve la lista cruda.
    """
    url = f'{GHL_API_BASE}/locations/{location_id}/customFields'
    if model:
        url += f'?model={model}'
    req = urllib.request.Request(url, headers={
        'Authorization': f'Bearer {GHL_TOKEN}',
        'Version': GHL_VERSION,
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    })
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            data = json.loads(r.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='replace')
        print(f'[ERROR HTTP {e.code}] {body}', file=sys.stderr)
        sys.exit(1)
    return data.get('customFields') or data.get('fields') or data


def normalize(fields):
    """Aplana cada field a un dict con campos relevantes."""
    out = []
    for f in fields:
        out.append({
            'id':        f.get('id') or f.get('_id') or '',
            'name':      f.get('name', ''),
            'fieldKey':  f.get('fieldKey', ''),
            'dataType':  f.get('dataType', '') or f.get('type', ''),
            'model':     f.get('model', '') or f.get('entityType', ''),
            'parentId':  f.get('parentId', '') or f.get('folderId', ''),
        })
    return out


def print_table(rows, title):
    print(f'\n────────────────────────────────────────────────────────────')
    print(f' {title} — {len(rows)} campos')
    print(f'────────────────────────────────────────────────────────────')
    if not rows:
        print('  (sin campos)')
        return
    # Anchos dinámicos
    widths = {
        'name':     max(20, min(40, max(len(r['name']) for r in rows) + 2)),
        'dataType': max(8,  min(15, max(len(r['dataType']) for r in rows) + 2)),
        'id':       24,
    }
    hdr = f"{'name':<{widths['name']}} {'dataType':<{widths['dataType']}} {'fieldKey':<35} ghl_field_id"
    print(hdr)
    print('-' * len(hdr))
    for r in sorted(rows, key=lambda x: (x['model'], x['name'].lower())):
        print(f"{r['name'][:widths['name']-1]:<{widths['name']}} "
              f"{r['dataType']:<{widths['dataType']}} "
              f"{r['fieldKey'][:34]:<35} "
              f"{r['id']}")


def main():
    location_id = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_LOCATION
    print(f'[GHL] location_id = {location_id}')

    # Consultar ambos endpoints — el endpoint sin filtro solo devuelve contactos.
    contact_raw = fetch_custom_fields(location_id, model='contact')
    opp_raw     = fetch_custom_fields(location_id, model='opportunity')
    contacts = normalize(contact_raw) if isinstance(contact_raw, list) else []
    opps     = normalize(opp_raw)     if isinstance(opp_raw, list)     else []

    print_table(contacts, 'CONTACT custom fields')
    print_table(opps,     'OPPORTUNITY custom fields')

    # CSV separado al final para copiar / pegar
    print('\n──── CSV (copia esto, marca canonical_key y data_type para los que quieres) ────')
    print('entity_type,ghl_field_id,ghl_field_name,fieldKey,dataType,canonical_key')
    for r in contacts:
        print(f"contact,{r['id']},{r['name']},{r['fieldKey']},{r['dataType']},")
    for r in opps:
        print(f"opportunity,{r['id']},{r['name']},{r['fieldKey']},{r['dataType']},")


if __name__ == '__main__':
    main()
