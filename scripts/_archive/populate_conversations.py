#!/usr/bin/env python3
"""
Pobla dim_conversations con los últimos 30 días de GHL.
Extrae el primer mensaje inbound de cada conversación.
Ejecutar directamente en el VPS.
"""
import json, time, subprocess, re
from datetime import datetime, timedelta, timezone

# ─── Config ──────────────────────────────────────────────────────────────────
API_KEY      = 'pit-6a8a2a21-4ec3-47c5-8096-5b5b80ad3351'
LOC_ID       = '0IP2MEmSx0fpdVllDK5b'
PG_CTR       = 'postgres_dashboard-postgres-1'
PG_USER      = 'ghl_user'
PG_DB        = 'ghl_analytics'
DAYS_BACK    = 30
CUTOFF       = datetime.now(timezone.utc) - timedelta(days=DAYS_BACK)
API_VER      = '2021-04-15'
BATCH_SZ     = 50
MAX_MSG_PAGES = 8

# ─── Utilidades ──────────────────────────────────────────────────────────────
REGEX_ID = re.compile(r'^[a-zA-Z0-9_-]{8,50}$')

def clean(val, maxlen=None):
    if val is None:
        return None
    s = str(val).strip()
    if maxlen:
        s = s[:maxlen]
    return s or None

def valid_id(val):
    if not val:
        return None
    s = str(val).strip()
    return s if REGEX_ID.match(s) else None

def parse_ts(val):
    if not val:
        return None
    try:
        if isinstance(val, (int, float)):
            return datetime.fromtimestamp(val / 1000, tz=timezone.utc).isoformat()
        s = str(val).strip()
        if s.isdigit() and len(s) == 13:
            return datetime.fromtimestamp(int(s) / 1000, tz=timezone.utc).isoformat()
        return datetime.fromisoformat(s.replace('Z', '+00:00')).isoformat()
    except Exception:
        return None

def sq(s):
    if s is None:
        return 'NULL'
    return "'" + str(s).replace("'", "''") + "'"

def ts_sql(val):
    ts = parse_ts(val)
    return f"{sq(ts)}::timestamptz" if ts else 'NULL'

def ghl_get(path, params=None):
    url = 'https://services.leadconnectorhq.com' + path
    if params:
        url += '?' + '&'.join(f'{k}={v}' for k, v in params.items())
    for attempt in range(5):
        proc = subprocess.run(
            ['curl', '-s', '-w', '\n__STATUS__%{http_code}',
             '-H', f'Authorization: Bearer {API_KEY}',
             '-H', f'Version: {API_VER}',
             url],
            capture_output=True, timeout=30
        )
        raw = proc.stdout.decode('utf-8', errors='replace')
        # Separar body y status code
        if '\n__STATUS__' in raw:
            body_str, status_str = raw.rsplit('\n__STATUS__', 1)
            status = int(status_str.strip())
        else:
            body_str, status = raw, 0

        if status == 429:
            wait = 2 ** (attempt + 1)
            print(f'  429 rate limit — esperando {wait}s...', flush=True)
            time.sleep(wait)
            continue
        if status != 200:
            raise Exception(f'HTTP {status}: {body_str[:300]}')
        return json.loads(body_str)
    raise Exception('Max reintentos alcanzado')

def psql(sql):
    proc = subprocess.run(
        ['docker', 'exec', '-i', PG_CTR,
         'psql', '-U', PG_USER, '-d', PG_DB, '-v', 'ON_ERROR_STOP=1'],
        input=sql.encode('utf-8'),
        capture_output=True, timeout=120
    )
    if proc.returncode != 0:
        raise Exception(f'psql error: {proc.stderr.decode()[:600]}')
    return proc.stdout.decode()

# ─── Paso 1: Fetch conversaciones ────────────────────────────────────────────
print(f'\n[1/3] Buscando conversaciones de los últimos {DAYS_BACK} días...', flush=True)
print(f'      Desde: {CUTOFF.strftime("%Y-%m-%d %H:%M UTC")}', flush=True)

all_convs    = []
start_after  = None
start_after_id = None
page         = 0

while True:
    params = {
        'locationId': LOC_ID,
        'limit': 100,
        'sort': 'desc',
    }
    if start_after:
        params['startAfter'] = start_after
    if start_after_id:
        params['startAfterId'] = start_after_id

    try:
        data = ghl_get('/conversations/search', params)
    except Exception as e:
        print(f'  ERROR en página {page}: {e}', flush=True)
        break

    convs = data.get('conversations', [])
    if not convs:
        break

    stop = False
    for c in convs:
        ts = parse_ts(c.get('lastMessageDate', ''))
        if ts:
            try:
                dt = datetime.fromisoformat(ts)
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                if dt < CUTOFF:
                    stop = True
                    break
            except Exception:
                pass
        all_convs.append(c)

    if stop:
        print(f'  Llegamos a conversaciones de hace +{DAYS_BACK} días. Fin de búsqueda.', flush=True)
        break

    meta         = data.get('meta', {})
    start_after  = meta.get('startAfter')
    start_after_id = meta.get('startAfterId')

    if not start_after and not start_after_id:
        break

    page += 1
    print(f'  Página {page}: +{len(convs)} | acumulado: {len(all_convs)}', flush=True)
    time.sleep(0.13)

print(f'  Total conversaciones: {len(all_convs)}', flush=True)

# ─── Paso 2: Primer mensaje inbound por conversación ─────────────────────────
print(f'\n[2/3] Extrayendo primer mensaje inbound...', flush=True)
first_msgs = {}  # conv_id -> {body, sent_at, dt}

for i, c in enumerate(all_convs):
    conv_id = c.get('id', '')
    if not conv_id:
        continue

    oldest   = None   # el inbound más antiguo encontrado
    last_mid = None   # cursor de paginación de mensajes

    for pg in range(MAX_MSG_PAGES):
        params = {'limit': 100}
        if last_mid:
            params['lastMessageId'] = last_mid

        try:
            data = ghl_get(f'/conversations/{conv_id}/messages', params)
        except Exception as e:
            print(f'  WARN mensajes {conv_id}: {e}', flush=True)
            break

        # GHL envuelve los mensajes en data.messages.messages
        inner = data.get('messages', data)
        if isinstance(inner, dict):
            msgs     = inner.get('messages', [])
            has_more = inner.get('nextPage', False)
            last_mid = inner.get('lastMessageId')
        elif isinstance(inner, list):
            msgs     = inner
            has_more = False
        else:
            break

        if not msgs:
            break

        for m in msgs:
            direction = str(m.get('direction', m.get('messageDirection', ''))).lower()
            body = m.get('body', '')
            if direction != 'inbound' or not body or not str(body).strip():
                continue
            ts = parse_ts(m.get('dateAdded') or m.get('createdAt'))
            if not ts:
                continue
            try:
                dt = datetime.fromisoformat(ts)
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                if oldest is None or dt < oldest['dt']:
                    oldest = {'body': str(body).strip()[:65535], 'sent_at': ts, 'dt': dt}
            except Exception:
                pass

        if not has_more or not last_mid:
            break
        time.sleep(0.12)

    if oldest:
        first_msgs[conv_id] = {'body': oldest['body'], 'sent_at': oldest['sent_at']}

    if (i + 1) % 25 == 0 or i == len(all_convs) - 1:
        pct = round((i + 1) / len(all_convs) * 100)
        print(f'  {i+1}/{len(all_convs)} ({pct}%) — primer msg encontrado en {len(first_msgs)}', flush=True)

    time.sleep(0.13)

print(f'  Primer mensaje inbound: {len(first_msgs)}/{len(all_convs)} conversaciones', flush=True)

# ─── Paso 3: Upsert en dim_conversations ─────────────────────────────────────
print(f'\n[3/3] Upsert en dim_conversations (lotes de {BATCH_SZ})...', flush=True)

def build_upsert(batch):
    rows = []
    for c in batch:
        conv_id    = valid_id(c.get('id'))
        contact_id = valid_id(c.get('contactId'))
        if not conv_id or not contact_id:
            continue

        fm = first_msgs.get(conv_id, {})

        rows.append(
            f"({sq(conv_id)},{sq(contact_id)},{sq(clean(c.get('locationId', LOC_ID), 30))},"
            f"{sq(clean(c.get('type') or c.get('channelType'), 30))},"
            f"{sq(valid_id(c.get('inboxId')))},"
            f"{sq(clean(c.get('inboxName'), 200))},"
            f"{sq(valid_id(c.get('userId') or c.get('assignedUserId')))},"
            f"{sq(clean(c.get('userName') or c.get('assignedUserName'), 200))},"
            f"{sq(clean(c.get('status'), 20))},"
            f"{int(c.get('unreadCount') or 0)},"
            f"{ts_sql(c.get('lastMessageDate') or c.get('lastMessageAt'))},"
            f"{sq(fm.get('body'))},"
            f"{ts_sql(fm.get('sent_at'))},"
            f"{ts_sql(c.get('dateAdded') or c.get('createdAt'))},"
            f"NOW(),TRUE,NOW())"
        )

    if not rows:
        return None

    return f"""
INSERT INTO dim_conversations (
    conversation_id, contact_id, location_id, channel_type,
    inbox_id, inbox_name, assigned_user_id, assigned_user_name,
    status, unread_count, last_message_at,
    first_inbound_body, first_inbound_at, ghl_created_at,
    valid_from, is_current, synced_at
) VALUES
{chr(10).join(',' + r if j > 0 else r for j, r in enumerate(rows))}
ON CONFLICT (conversation_id) WHERE is_current = TRUE DO UPDATE SET
    status             = EXCLUDED.status,
    unread_count       = EXCLUDED.unread_count,
    last_message_at    = EXCLUDED.last_message_at,
    assigned_user_id   = EXCLUDED.assigned_user_id,
    assigned_user_name = EXCLUDED.assigned_user_name,
    first_inbound_body = CASE WHEN dim_conversations.first_inbound_body IS NULL
                              THEN EXCLUDED.first_inbound_body
                              ELSE dim_conversations.first_inbound_body END,
    first_inbound_at   = CASE WHEN dim_conversations.first_inbound_at IS NULL
                              THEN EXCLUDED.first_inbound_at
                              ELSE dim_conversations.first_inbound_at END,
    synced_at          = NOW();
"""

total_inserted = 0
for start in range(0, len(all_convs), BATCH_SZ):
    batch = all_convs[start:start + BATCH_SZ]
    sql   = build_upsert(batch)
    if not sql:
        continue
    try:
        out = psql(sql)
        # psql reports "INSERT 0 N"
        m = re.search(r'INSERT 0 (\d+)', out)
        n = int(m.group(1)) if m else len(batch)
        total_inserted += n
        print(f'  Lote {start//BATCH_SZ + 1}: {n} filas | acumulado: {total_inserted}', flush=True)
    except Exception as e:
        print(f'  ERROR lote {start//BATCH_SZ + 1}: {e}', flush=True)

# ─── Resumen final ────────────────────────────────────────────────────────────
print(f'\n[OK] Completado.', flush=True)
result = psql("SELECT COUNT(*) as total, COUNT(first_inbound_body) as con_primer_msg FROM dim_conversations WHERE is_current = TRUE AND location_id = '" + LOC_ID + "';")
print(result)
