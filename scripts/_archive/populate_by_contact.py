#!/usr/bin/env python3
"""
Pobla dim_conversations buscando conversaciones por contacto.
Solo contactos creados en los ultimos 30 dias que no esten ya en dim_conversations.
"""
import json, time, subprocess, re
from datetime import datetime, timezone

API_KEY = 'pit-6a8a2a21-4ec3-47c5-8096-5b5b80ad3351'
LOC_ID  = '0IP2MEmSx0fpdVllDK5b'
PG_CTR  = 'postgres_dashboard-postgres-1'
PG_USER = 'ghl_user'
PG_DB   = 'ghl_analytics'
BATCH   = 50

REGEX_ID = re.compile(r'^[a-zA-Z0-9_-]{8,50}$')

def clean(v, n=None):
    if v is None: return None
    s = str(v).strip()
    return (s[:n] if n else s) or None

def vid(v):
    if not v: return None
    s = str(v).strip()
    return s if REGEX_ID.match(s) else None

def pts(v):
    if not v: return None
    try:
        if isinstance(v, (int, float)):
            return datetime.fromtimestamp(v / 1000, tz=timezone.utc).isoformat()
        s = str(v).strip()
        if s.isdigit() and len(s) == 13:
            return datetime.fromtimestamp(int(s) / 1000, tz=timezone.utc).isoformat()
        return datetime.fromisoformat(s.replace('Z', '+00:00')).isoformat()
    except Exception:
        return None

def sq(s):
    if s is None: return 'NULL'
    return "'" + str(s).replace("'", "''") + "'"

def ts_sql(v):
    t = pts(v)
    return (sq(t) + '::timestamptz') if t else 'NULL'

def curl(url):
    r = subprocess.run(
        ['curl', '-s', '-w', '\n__S__%{http_code}',
         '-H', f'Authorization: Bearer {API_KEY}',
         '-H', 'Version: 2021-04-15', url],
        capture_output=True, timeout=30)
    raw = r.stdout.decode('utf-8', 'replace')
    if '\n__S__' in raw:
        body, code = raw.rsplit('\n__S__', 1)
        code = int(code.strip())
    else:
        body, code = raw, 0
    if code == 429:
        raise Exception('429')
    if code != 200:
        raise Exception(f'HTTP {code}: {body[:200]}')
    return json.loads(body)

def psql(sql):
    r = subprocess.run(
        ['docker', 'exec', '-i', PG_CTR,
         'psql', '-U', PG_USER, '-d', PG_DB, '-v', 'ON_ERROR_STOP=1'],
        input=sql.encode('utf-8'), capture_output=True, timeout=120)
    if r.returncode != 0:
        raise Exception(r.stderr.decode()[:400])
    return r.stdout.decode()

# ── 1. Contactos de los ultimos 30 dias sin conversacion ya registrada ────────
print('[1/3] Leyendo contactos pendientes de los ultimos 30 dias...', flush=True)

sql_contacts = """
SELECT contact_id FROM dim_contacts
WHERE is_current = TRUE
  AND ghl_created_at > NOW() - INTERVAL '30 days'
  AND contact_id NOT IN (
      SELECT DISTINCT contact_id FROM dim_conversations WHERE is_current = TRUE
  )
ORDER BY ghl_created_at DESC;
"""
out = psql(sql_contacts)
contact_ids = [ln.strip() for ln in out.splitlines() if REGEX_ID.match(ln.strip())]
print(f'  Contactos pendientes: {len(contact_ids)}', flush=True)

# ── 2. Fetch conversacion + primer mensaje inbound por contacto ───────────────
print('[2/3] Fetch conversaciones + primer mensaje inbound...', flush=True)

all_convs  = []
first_msgs = {}   # conv_id -> {body, sent_at}

for i, cid in enumerate(contact_ids):
    # Conversaciones del contacto
    try:
        d = curl(
            f'https://services.leadconnectorhq.com/conversations/search'
            f'?locationId={LOC_ID}&contactId={cid}&limit=50'
        )
        convs = d.get('conversations', [])
    except Exception as e:
        if '429' in str(e):
            time.sleep(5)
        convs = []

    for c in convs:
        conv_id = c.get('id', '')
        if not conv_id:
            continue
        all_convs.append(c)

        # Primer mensaje inbound de la conversacion
        oldest   = None
        last_mid = None
        for pg in range(6):
            params = 'limit=100' + (f'&lastMessageId={last_mid}' if last_mid else '')
            try:
                md = curl(
                    f'https://services.leadconnectorhq.com/conversations/{conv_id}/messages?{params}'
                )
            except Exception:
                break
            inner    = md.get('messages', md)
            msgs     = inner.get('messages', []) if isinstance(inner, dict) else (inner if isinstance(inner, list) else [])
            has_more = inner.get('nextPage', False) if isinstance(inner, dict) else False
            last_mid = inner.get('lastMessageId') if isinstance(inner, dict) else None
            for m in msgs:
                dirn = str(m.get('direction', m.get('messageDirection', ''))).lower()
                body = m.get('body', '')
                if dirn != 'inbound' or not body or not str(body).strip():
                    continue
                t = pts(m.get('dateAdded') or m.get('createdAt'))
                if not t:
                    continue
                try:
                    dt = datetime.fromisoformat(t)
                    if dt.tzinfo is None:
                        dt = dt.replace(tzinfo=timezone.utc)
                    if oldest is None or dt < oldest['dt']:
                        oldest = {'body': str(body).strip()[:65535], 'sent_at': t, 'dt': dt}
                except Exception:
                    pass
            if not has_more or not last_mid:
                break
            time.sleep(0.1)

        if oldest:
            first_msgs[conv_id] = {'body': oldest['body'], 'sent_at': oldest['sent_at']}

    time.sleep(0.13)
    if (i + 1) % 50 == 0 or i == len(contact_ids) - 1:
        pct = round((i + 1) / len(contact_ids) * 100)
        print(f'  {i+1}/{len(contact_ids)} ({pct}%) | convs: {len(all_convs)} | con_msg: {len(first_msgs)}', flush=True)

print(f'  Total conversaciones: {len(all_convs)} | primer_msg: {len(first_msgs)}', flush=True)

# ── 3. Upsert en dim_conversations ───────────────────────────────────────────
print(f'[3/3] Upsert (lotes de {BATCH})...', flush=True)

def build_upsert(batch):
    rows = []
    for c in batch:
        conv_id    = vid(c.get('id'))
        contact_id = vid(c.get('contactId'))
        if not conv_id or not contact_id:
            continue
        fm = first_msgs.get(conv_id, {})
        rows.append(
            f"({sq(conv_id)},{sq(contact_id)},"
            f"{sq(clean(c.get('locationId', LOC_ID), 30))},"
            f"{sq(clean(c.get('type') or c.get('channelType'), 30))},"
            f"{sq(vid(c.get('inboxId')))},"
            f"{sq(clean(c.get('inboxName'), 200))},"
            f"{sq(vid(c.get('assignedTo') or c.get('userId')))},"
            f"{sq(clean(c.get('contactName') or c.get('fullName'), 200))},"
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
    cols = (
        'conversation_id,contact_id,location_id,channel_type,'
        'inbox_id,inbox_name,assigned_user_id,assigned_user_name,'
        'status,unread_count,last_message_at,'
        'first_inbound_body,first_inbound_at,ghl_created_at,'
        'valid_from,is_current,synced_at'
    )
    return (
        f'INSERT INTO dim_conversations ({cols}) VALUES\n'
        + ',\n'.join(rows)
        + '\nON CONFLICT (conversation_id) WHERE is_current = TRUE DO UPDATE SET\n'
        + '  status             = EXCLUDED.status,\n'
        + '  unread_count       = EXCLUDED.unread_count,\n'
        + '  last_message_at    = EXCLUDED.last_message_at,\n'
        + '  assigned_user_id   = EXCLUDED.assigned_user_id,\n'
        + '  assigned_user_name = EXCLUDED.assigned_user_name,\n'
        + '  first_inbound_body = CASE WHEN dim_conversations.first_inbound_body IS NULL\n'
        + '                            THEN EXCLUDED.first_inbound_body\n'
        + '                            ELSE dim_conversations.first_inbound_body END,\n'
        + '  first_inbound_at   = CASE WHEN dim_conversations.first_inbound_at IS NULL\n'
        + '                            THEN EXCLUDED.first_inbound_at\n'
        + '                            ELSE dim_conversations.first_inbound_at END,\n'
        + '  synced_at          = NOW();'
    )

total = 0
for s in range(0, len(all_convs), BATCH):
    sql = build_upsert(all_convs[s:s + BATCH])
    if not sql:
        continue
    try:
        out = psql(sql)
        m   = re.search(r'INSERT 0 (\d+)', out)
        n   = int(m.group(1)) if m else BATCH
        total += n
        print(f'  Lote {s // BATCH + 1}: {n} | acumulado: {total}', flush=True)
    except Exception as e:
        print(f'  ERROR lote {s // BATCH + 1}: {e}', flush=True)

# Resumen final
out = psql(
    f"SELECT COUNT(*) as total, COUNT(first_inbound_body) as con_msg "
    f"FROM dim_conversations WHERE is_current=TRUE AND location_id='{LOC_ID}';"
)
print('\n[OK] Resultado final:')
print(out)
