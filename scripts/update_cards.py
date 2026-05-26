import json
import urllib.request
import urllib.error

API = 'https://analytics.sixteam.pro/api'
KEY = 'mb_L7PguW9hT8EfzuwVGeBJk0sQX1x/cSOdwPuOXFDD0nU='

TAGS = {
    'fecha_inicio': {
        'id': 'fecha_inicio', 'name': 'fecha_inicio',
        'display-name': 'Fecha Inicio', 'type': 'text', 'required': False
    },
    'fecha_fin': {
        'id': 'fecha_fin', 'name': 'fecha_fin',
        'display-name': 'Fecha Fin', 'type': 'text', 'required': False
    }
}

def put_card(card_id, query, display=None, name=None):
    payload = {
        'dataset_query': {
            'database': 2,
            'type': 'native',
            'native': {'query': query, 'template-tags': TAGS}
        }
    }
    if display:
        payload['display'] = display
    if name:
        payload['name'] = name
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f'{API}/card/{card_id}', data=data, method='PUT',
        headers={'Content-Type': 'application/json', 'x-api-key': KEY}
    )
    try:
        with urllib.request.urlopen(req) as r:
            resp = json.load(r)
            print(f'Card {card_id} OK: {resp.get("name")}')
            return resp.get('id')
    except urllib.error.HTTPError as e:
        print(f'Card {card_id} ERROR {e.code}: {e.read().decode()[:300]}')

def post_card(query, name, display='table', collection_id=None):
    payload = {
        'name': name,
        'display': display,
        'dataset_query': {
            'database': 2,
            'type': 'native',
            'native': {'query': query, 'template-tags': TAGS}
        },
        'visualization_settings': {}
    }
    if collection_id:
        payload['collection_id'] = collection_id
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f'{API}/card', data=data, method='POST',
        headers={'Content-Type': 'application/json', 'x-api-key': KEY}
    )
    try:
        with urllib.request.urlopen(req) as r:
            resp = json.load(r)
            print(f'New card created: id={resp.get("id")} name={resp.get("name")}')
            return resp.get('id')
    except urllib.error.HTTPError as e:
        print(f'POST card ERROR {e.code}: {e.read().decode()[:300]}')

# ── CARD 80 ── Embudo por Anuncio
q80 = """SELECT
  COALESCE(da.ad_name, dc.ad_name_first)           AS nombre_anuncio,
  dc.campaign_id_first                              AS ad_id,
  COUNT(DISTINCT dc.contact_id)                     AS total_contactos,
  COUNT(DISTINCT a.appointment_id)                  AS con_cita,
  COUNT(DISTINCT do2.opportunity_id)                AS en_pipeline_avanzado,
  ROUND(100.0 * COUNT(DISTINCT a.appointment_id)
    / NULLIF(COUNT(DISTINCT dc.contact_id), 0), 1) AS tasa_cita_pct
FROM dim_contacts dc
LEFT JOIN dim_ads da         ON da.ad_id           = dc.campaign_id_first
LEFT JOIN ghl_appointments a ON a.contact_id       = dc.contact_id
LEFT JOIN dim_opportunities do2 ON do2.contact_id  = dc.contact_id AND do2.is_current = true
LEFT JOIN dim_pipelines dp   ON dp.stage_id        = do2.pipeline_stage_id
WHERE dc.is_current = true
  AND (dc.ad_name_first IS NOT NULL OR dc.campaign_id_first IS NOT NULL)
  AND (dp.stage_name IN ('Calendario','Agendó Visita','Hot','Cierre Ganado') OR dp.stage_name IS NULL)
[[AND dc.ghl_created_at >= {{fecha_inicio}}::date]]
[[AND dc.ghl_created_at <= {{fecha_fin}}::date]]
GROUP BY 1, 2
ORDER BY total_contactos DESC
LIMIT 15"""

# ── CARD 81 ── Citas por Mes y Anuncio
q81 = """SELECT
  DATE_TRUNC('month', a.start_time)::date    AS mes,
  COALESCE(da.ad_name, dc.ad_name_first)     AS nombre_anuncio,
  COUNT(DISTINCT a.appointment_id)           AS citas
FROM ghl_appointments a
JOIN dim_contacts dc ON dc.contact_id = a.contact_id AND dc.is_current = true
LEFT JOIN dim_ads da  ON da.ad_id = dc.campaign_id_first
WHERE (dc.ad_name_first IS NOT NULL OR dc.campaign_id_first IS NOT NULL)
[[AND dc.ghl_created_at >= {{fecha_inicio}}::date]]
[[AND dc.ghl_created_at <= {{fecha_fin}}::date]]
GROUP BY 1, 2
ORDER BY 1, 3 DESC"""

# ── CARD 82 ── Pipeline Avanzado por Anuncio
q82 = """SELECT
  COALESCE(da.ad_name, dc.ad_name_first)     AS nombre_anuncio,
  dc.campaign_id_first                        AS ad_id,
  COUNT(DISTINCT do2.opportunity_id)          AS oportunidades
FROM dim_opportunities do2
JOIN dim_contacts dc ON dc.contact_id = do2.contact_id AND dc.is_current = true
LEFT JOIN dim_ads da  ON da.ad_id = dc.campaign_id_first
JOIN dim_pipelines dp ON dp.stage_id = do2.pipeline_stage_id
WHERE do2.is_current = true
  AND dp.stage_name IN ('Calendario','Agendó Visita','Hot','Cierre Ganado')
  AND (dc.ad_name_first IS NOT NULL OR dc.campaign_id_first IS NOT NULL)
[[AND dc.ghl_created_at >= {{fecha_inicio}}::date]]
[[AND dc.ghl_created_at <= {{fecha_fin}}::date]]
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 15"""

# ── NEW CARD: Contactos por Fuente y Medio (UTM)
q_fuente = """SELECT
  COALESCE(dc.utm_source_first, 'Sin fuente') AS fuente,
  COALESCE(dc.utm_medium_first, '—')          AS medio,
  COUNT(*)                                     AS contactos
FROM dim_contacts dc
WHERE dc.is_current = true
[[AND dc.ghl_created_at >= {{fecha_inicio}}::date]]
[[AND dc.ghl_created_at <= {{fecha_fin}}::date]]
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 20"""

# ── NEW CARD: Citas por Fuente UTM del Contacto
q_citas_utm = """SELECT
  COALESCE(dc.utm_source_first, 'Sin fuente') AS fuente,
  COALESCE(dc.utm_medium_first, '—')          AS medio,
  COUNT(DISTINCT a.appointment_id)             AS citas
FROM ghl_appointments a
JOIN dim_contacts dc ON dc.contact_id = a.contact_id AND dc.is_current = true
[[WHERE dc.ghl_created_at >= {{fecha_inicio}}::date]]
[[AND dc.ghl_created_at <= {{fecha_fin}}::date]]
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 20"""

# Run updates
put_card(80, q80, display='table')
put_card(81, q81, display='line')
put_card(82, q82, display='bar')

# Create new cards
new_id_1 = post_card(q_fuente,    name='Contactos por Fuente y Medio (UTM)', display='table')
new_id_2 = post_card(q_citas_utm, name='Citas por Fuente UTM del Contacto',  display='table')

print(f'\nNew card IDs: {new_id_1}, {new_id_2}')

# Add new cards to Dashboard 2
if new_id_1 and new_id_2:
    # Get current dashboard to find existing cards and layout
    req = urllib.request.Request(
        f'{API}/dashboard/2',
        headers={'x-api-key': KEY}
    )
    with urllib.request.urlopen(req) as r:
        dash = json.load(r)

    existing_cards = dash.get('dashcards', [])
    print(f'Dashboard has {len(existing_cards)} existing cards')

    # Find max row used
    max_row = 0
    for c in existing_cards:
        max_row = max(max_row, c.get('row', 0) + c.get('size_y', 4))

    new_cards = [
        {
            'card_id': new_id_1,
            'col': 0, 'row': max_row,
            'size_x': 12, 'size_y': 8
        },
        {
            'card_id': new_id_2,
            'col': 12, 'row': max_row,
            'size_x': 12, 'size_y': 8
        }
    ]

    add_payload = json.dumps({'cards': new_cards}).encode()
    add_req = urllib.request.Request(
        f'{API}/dashboard/2/cards',
        data=add_payload, method='PUT',
        headers={'Content-Type': 'application/json', 'x-api-key': KEY}
    )
    try:
        with urllib.request.urlopen(add_req) as r:
            result = json.load(r)
            print(f'Dashboard 2 updated with new cards. Response keys: {list(result.keys()) if isinstance(result, dict) else type(result)}')
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f'Dashboard PUT ERROR {e.code}: {body[:500]}')
        # Try POST instead
        print('Trying POST /api/dashboard/2/cards for each card...')
        for nc in new_cards:
            single = json.dumps({'cardId': nc['card_id'], 'col': nc['col'], 'row': nc['row'], 'size_x': nc['size_x'], 'size_y': nc['size_y']}).encode()
            post_req = urllib.request.Request(
                f'{API}/dashboard/2/cards',
                data=single, method='POST',
                headers={'Content-Type': 'application/json', 'x-api-key': KEY}
            )
            try:
                with urllib.request.urlopen(post_req) as r2:
                    r2_body = json.load(r2)
                    print(f'  Added card {nc["card_id"]} to dashboard: id={r2_body.get("id")}')
            except urllib.error.HTTPError as e2:
                print(f'  POST card {nc["card_id"]} ERROR {e2.code}: {e2.read().decode()[:300]}')
