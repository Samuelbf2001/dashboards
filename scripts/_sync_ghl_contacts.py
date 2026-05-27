"""
Sync completo de contactos GHL -> dim_contacts en el VPS.

Estrategia UPSERT:
  - dim_contacts NO tiene UNIQUE constraint sobre (contact_id) WHERE is_current.
  - PK es surrogate_key (bigserial).
  - Usamos UPDATE ... WHERE contact_id=X AND is_current=TRUE para actualizar,
    e INSERT si no existe ninguna fila is_current=TRUE para ese contact_id.
  - Todo via archivo SQL temporal en el container (igual que _apply_migration_vps.py).

Uso:
  python _sync_ghl_contacts.py [--dry-run] [--limit N]

Opciones:
  --dry-run   Genera el SQL pero no lo ejecuta en la BD.
  --limit N   Procesa solo los primeros N contactos (para prueba).
"""

import sys
import json
import time
import urllib.request
import urllib.error
import paramiko

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# ─── Configuración ────────────────────────────────────────────────────────────
GHL_API_BASE  = 'https://services.leadconnectorhq.com'
GHL_TOKEN     = 'pit-6a8a2a21-4ec3-47c5-8096-5b5b80ad3351'
GHL_VERSION   = '2021-07-28'
GHL_LOCATION  = '0IP2MEmSx0fpdVllDK5b'   # milotecucuta
GHL_PAGE_SIZE = 100

VPS_HOST  = '72.60.67.214'
VPS_USER  = 'root'
VPS_PWD   = 'Sixteam2026-'

PG_CONTAINER = 'postgres_dashboard-postgres-1'
PG_USER      = 'ghl_user'
PG_DB        = 'ghl_analytics'

SLEEP_BETWEEN_PAGES = 0.35   # segundos entre llamadas API (evita 429)

# ─── Helpers de API ───────────────────────────────────────────────────────────

def ghl_get(path, params=None):
    """Hace GET a la API de GHL. Devuelve dict JSON o lanza excepción."""
    url = GHL_API_BASE + path
    if params:
        qs = '&'.join(f'{k}={urllib.request.quote(str(v))}' for k, v in params.items())
        url = f'{url}?{qs}'
    req = urllib.request.Request(url, headers={
        'Authorization': f'Bearer {GHL_TOKEN}',
        'Version':       GHL_VERSION,
        'Accept':        'application/json',
        'User-Agent':    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                         'AppleWebKit/537.36 (KHTML, like Gecko) '
                         'Chrome/131.0.0.0 Safari/537.36',
    })
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = 5 * (attempt + 1)
                print(f'  [429 rate limit] esperando {wait}s...', flush=True)
                time.sleep(wait)
                continue
            body = e.read().decode('utf-8', errors='replace')
            raise RuntimeError(f'HTTP {e.code} en {path}: {body}') from e
        except urllib.error.URLError as e:
            if attempt < 2:
                time.sleep(3)
                continue
            raise
    raise RuntimeError(f'3 intentos fallidos en {path}')


# ─── Mapeo de campos GHL -> columnas DB ───────────────────────────────────────

def safe_str(val, maxlen=None):
    """Convierte a str, recorta, o None si vacío."""
    if val is None:
        return None
    s = str(val).strip()
    if not s:
        return None
    if maxlen:
        s = s[:maxlen]
    return s


def map_contact(c):
    """Mapea un objeto contact de GHL a un dict con columnas de dim_contacts."""
    attr  = c.get('attributionSource') or {}
    lattr = c.get('lastAttributionSource') or {}

    # custom_fields: GHL puede devolver lista de {id, value} o dict
    raw_cf = c.get('customFields') or c.get('customField') or None
    cf_json = None
    if isinstance(raw_cf, list):
        cf_json = json.dumps({item['id']: item.get('value') for item in raw_cf if 'id' in item})
    elif isinstance(raw_cf, dict):
        cf_json = json.dumps(raw_cf)

    return {
        'contact_id':         safe_str(c.get('id'), 50),
        'location_id':        GHL_LOCATION,
        'first_name':         safe_str(c.get('firstName'), 100),
        'last_name':          safe_str(c.get('lastName'), 100),
        'email':              safe_str(c.get('email'), 255),
        'phone':              safe_str(c.get('phone'), 20),
        'source':             safe_str(c.get('source'), 100),
        'contact_type':       safe_str(c.get('type') or c.get('contactType'), 50),
        'dnd':                bool(c.get('dnd', False)),
        'ghl_created_at':     safe_str(c.get('dateAdded')),
        'ghl_updated_at':     safe_str(c.get('dateUpdated')),
        # Atribución primer toque
        'utm_source_first':   safe_str(attr.get('utmSource'), 200),
        'utm_medium_first':   safe_str(attr.get('utmMedium'), 200),
        'utm_campaign_first': safe_str(attr.get('utmCampaign'), 200),
        'utm_content_first':  safe_str(attr.get('utmContent'), 200),
        'utm_term_first':     safe_str(attr.get('utmTerm'), 200),
        'landing_url_first':  safe_str(attr.get('url') or attr.get('landingPage')),
        'referrer_first':     safe_str(attr.get('referrer')),
        'gclid_first':        safe_str(attr.get('gclid'), 200),
        'fbclid_first':       safe_str(attr.get('fbclid'), 200),
        'ad_id_first':        safe_str(attr.get('utmAdId') or attr.get('adId'), 100),
        'ad_name_first':      safe_str(attr.get('adName') or attr.get('utmAdName'), 500),
        'ctwa_clid_first':    safe_str(attr.get('ctwa_clid') or attr.get('ctwaClid'), 500),
        # Atribución último toque
        'ad_id_last':         safe_str(lattr.get('utmAdId') or lattr.get('adId'), 100),
        'ad_name_last':       safe_str(lattr.get('adName') or lattr.get('utmAdName'), 500),
        'ctwa_clid_last':     safe_str(lattr.get('ctwa_clid') or lattr.get('ctwaClid'), 500),
        'utm_source_last':    safe_str(lattr.get('utmSource'), 200),
        'utm_medium_last':    safe_str(lattr.get('utmMedium'), 200),
        'utm_campaign_last':  safe_str(lattr.get('utmCampaign'), 200),
        'utm_content_last':   safe_str(lattr.get('utmContent'), 200),
        'landing_url_last':   safe_str(lattr.get('url') or lattr.get('landingPage')),
        'custom_fields':      cf_json,
    }


# ─── Generación SQL ───────────────────────────────────────────────────────────

def pg_literal(val):
    """Convierte un valor Python a literal SQL seguro (sin parámetros bind)."""
    if val is None:
        return 'NULL'
    if isinstance(val, bool):
        return 'TRUE' if val else 'FALSE'
    if isinstance(val, (int, float)):
        return str(val)
    # String: escape apóstrofos con ''
    escaped = str(val).replace("'", "''")
    return f"'{escaped}'"


def build_upsert_sql(contacts_mapped):
    """
    Genera SQL de upsert BULK para un batch de contactos mapeados.

    Estrategia de una sola transacción con tres CTEs:
      1. incoming  — VALUES de los contactos nuevos del batch
      2. updated   — UPDATE de filas is_current=TRUE existentes (JOIN con incoming)
      3. INSERT ... SELECT — inserta solo los que no tuvieron match en updated

    Esto emite 2 statements SQL en lugar de 100 DO $$ bloques, logrando ~50x
    de speedup en batches de 100 filas.
    """
    if not contacts_mapped:
        return ''

    # Construir filas VALUES: una por contacto, en el orden de columnas de incoming
    value_rows = []
    for row in contacts_mapped:
        cf = row['custom_fields']
        cf_cast = f"{pg_literal(cf)}::jsonb" if cf is not None else 'NULL::jsonb'
        value_rows.append(
            f"  ({pg_literal(row['contact_id'])},"
            f" {pg_literal(row['location_id'])},"
            f" {pg_literal(row['email'])},"
            f" {pg_literal(row['phone'])},"
            f" {pg_literal(row['first_name'])},"
            f" {pg_literal(row['last_name'])},"
            f" {pg_literal(row['source'])},"
            f" {pg_literal(row['contact_type'])},"
            f" {pg_literal(row['dnd'])},"
            f" {cf_cast},"
            f" {pg_literal(row['utm_source_first'])},"
            f" {pg_literal(row['utm_medium_first'])},"
            f" {pg_literal(row['utm_campaign_first'])},"
            f" {pg_literal(row['utm_content_first'])},"
            f" {pg_literal(row['utm_term_first'])},"
            f" {pg_literal(row['landing_url_first'])},"
            f" {pg_literal(row['referrer_first'])},"
            f" {pg_literal(row['gclid_first'])},"
            f" {pg_literal(row['fbclid_first'])},"
            f" {pg_literal(row['ad_id_first'])},"
            f" {pg_literal(row['ad_name_first'])},"
            f" {pg_literal(row['ctwa_clid_first'])},"
            f" {pg_literal(row['ad_id_last'])},"
            f" {pg_literal(row['ad_name_last'])},"
            f" {pg_literal(row['ctwa_clid_last'])},"
            f" {pg_literal(row['utm_source_last'])},"
            f" {pg_literal(row['utm_medium_last'])},"
            f" {pg_literal(row['utm_campaign_last'])},"
            f" {pg_literal(row['utm_content_last'])},"
            f" {pg_literal(row['landing_url_last'])},"
            f" {pg_literal(row['ghl_created_at'])},"
            f" {pg_literal(row['ghl_updated_at'])})"
        )

    values_clause = ',\n'.join(value_rows)

    sql = f"""\
BEGIN;

WITH incoming(
  contact_id, location_id, email, phone, first_name, last_name,
  source, contact_type, dnd, custom_fields,
  utm_source_first, utm_medium_first, utm_campaign_first,
  utm_content_first, utm_term_first, landing_url_first,
  referrer_first, gclid_first, fbclid_first,
  ad_id_first, ad_name_first, ctwa_clid_first,
  ad_id_last, ad_name_last, ctwa_clid_last,
  utm_source_last, utm_medium_last, utm_campaign_last,
  utm_content_last, landing_url_last,
  ghl_created_at, ghl_updated_at
) AS (VALUES
{values_clause}
),
updated AS (
  UPDATE dim_contacts dc
  SET
    first_name         = i.first_name,
    last_name          = i.last_name,
    email              = i.email,
    phone              = i.phone,
    source             = COALESCE(dc.source,             i.source),
    contact_type       = i.contact_type,
    dnd                = i.dnd,
    ghl_updated_at     = i.ghl_updated_at::timestamptz,
    utm_source_first   = COALESCE(dc.utm_source_first,   i.utm_source_first),
    utm_medium_first   = COALESCE(dc.utm_medium_first,   i.utm_medium_first),
    utm_campaign_first = COALESCE(dc.utm_campaign_first, i.utm_campaign_first),
    utm_content_first  = COALESCE(dc.utm_content_first,  i.utm_content_first),
    utm_term_first     = COALESCE(dc.utm_term_first,     i.utm_term_first),
    landing_url_first  = COALESCE(dc.landing_url_first,  i.landing_url_first),
    referrer_first     = COALESCE(dc.referrer_first,     i.referrer_first),
    gclid_first        = COALESCE(dc.gclid_first,        i.gclid_first),
    fbclid_first       = COALESCE(dc.fbclid_first,       i.fbclid_first),
    ad_id_first        = COALESCE(dc.ad_id_first,        i.ad_id_first),
    ad_name_first      = COALESCE(dc.ad_name_first,      i.ad_name_first),
    ctwa_clid_first    = COALESCE(dc.ctwa_clid_first,    i.ctwa_clid_first),
    ad_id_last         = i.ad_id_last,
    ad_name_last       = i.ad_name_last,
    ctwa_clid_last     = i.ctwa_clid_last,
    utm_source_last    = i.utm_source_last,
    utm_medium_last    = i.utm_medium_last,
    utm_campaign_last  = i.utm_campaign_last,
    utm_content_last   = i.utm_content_last,
    landing_url_last   = i.landing_url_last,
    custom_fields      = COALESCE(i.custom_fields, dc.custom_fields),
    synced_at          = NOW()
  FROM incoming i
  WHERE dc.contact_id = i.contact_id AND dc.is_current = TRUE
  RETURNING dc.contact_id
)
INSERT INTO dim_contacts (
  contact_id, location_id, email, phone, first_name, last_name,
  source, contact_type, dnd, custom_fields,
  utm_source_first, utm_medium_first, utm_campaign_first,
  utm_content_first, utm_term_first, landing_url_first,
  referrer_first, gclid_first, fbclid_first,
  ad_id_first, ad_name_first, ctwa_clid_first,
  ad_id_last, ad_name_last, ctwa_clid_last,
  utm_source_last, utm_medium_last, utm_campaign_last,
  utm_content_last, landing_url_last,
  ghl_created_at, ghl_updated_at,
  is_current, valid_from, synced_at
)
SELECT
  i.contact_id, i.location_id, i.email, i.phone, i.first_name, i.last_name,
  i.source, i.contact_type, i.dnd, i.custom_fields,
  i.utm_source_first, i.utm_medium_first, i.utm_campaign_first,
  i.utm_content_first, i.utm_term_first, i.landing_url_first,
  i.referrer_first, i.gclid_first, i.fbclid_first,
  i.ad_id_first, i.ad_name_first, i.ctwa_clid_first,
  i.ad_id_last, i.ad_name_last, i.ctwa_clid_last,
  i.utm_source_last, i.utm_medium_last, i.utm_campaign_last,
  i.utm_content_last, i.landing_url_last,
  i.ghl_created_at::timestamptz, i.ghl_updated_at::timestamptz,
  TRUE, NOW(), NOW()
FROM incoming i
WHERE i.contact_id NOT IN (SELECT contact_id FROM updated);

COMMIT;
"""
    return sql


# ─── SSH helpers ──────────────────────────────────────────────────────────────

def exec_sql_on_vps(client, sql_content, label='batch'):
    """
    Ejecuta sql_content en el container postgres usando stdin piping:
      echo SQL | docker exec -i container psql ...
    Elimina el round-trip de SFTP + docker cp — una sola llamada SSH.
    """
    cmd = (
        f'docker exec -i {PG_CONTAINER} '
        f'psql -U {PG_USER} -d {PG_DB} '
        f'-v ON_ERROR_STOP=1 -P pager=off 2>&1'
    )
    transport = client.get_transport()
    chan = transport.open_session()
    chan.set_combine_stderr(True)
    chan.exec_command(cmd)

    # Enviar SQL por stdin y cerrar
    sql_bytes = sql_content.encode('utf-8')
    chan.sendall(sql_bytes)
    chan.shutdown_write()   # EOF en stdin -> psql termina de leer y procesa

    # Leer output (con timeout de 120s)
    out_chunks = []
    import socket
    chan.settimeout(120)
    try:
        while True:
            chunk = chan.recv(65536)
            if not chunk:
                break
            out_chunks.append(chunk)
    except socket.timeout:
        out_chunks.append(b'\n[WARN] channel recv timeout')

    chan.close()
    out = b''.join(out_chunks).decode('utf-8', errors='replace')
    return out, ''


def run_cmd(client, cmd, timeout=60):
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    return out, err


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    dry_run   = '--dry-run' in sys.argv
    limit     = None
    if '--limit' in sys.argv:
        idx   = sys.argv.index('--limit')
        limit = int(sys.argv[idx + 1])

    print('=' * 60)
    print(f'  GHL -> dim_contacts SYNC  (location: {GHL_LOCATION})')
    print(f'  dry_run={dry_run}  limit={limit}')
    print('=' * 60)

    # ── Conectar SSH ──────────────────────────────────────────────────────────
    if not dry_run:
        print('\n[SSH] conectando al VPS...')
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_HOST, username=VPS_USER, password=VPS_PWD, timeout=20)
        print('[SSH] conectado')
    else:
        ssh = None

    # ── Paginación GHL ────────────────────────────────────────────────────────
    # GHL requiere DOS cursores para paginar correctamente:
    #   startAfterId  — ID del último contacto de la página
    #   startAfter    — timestamp (ms epoch) del último contacto de la página
    # Ambos vienen en meta.startAfterId y meta.startAfter de la respuesta.
    total_fetched   = 0
    total_processed = 0
    total_errors    = 0
    page_num        = 0
    cursor_id       = None   # meta.startAfterId
    cursor_ts       = None   # meta.startAfter  (int, ms epoch)

    while True:
        page_num += 1
        params = {
            'locationId': GHL_LOCATION,
            'limit':      GHL_PAGE_SIZE,
        }
        if cursor_id:
            params['startAfterId'] = cursor_id
        if cursor_ts is not None:
            params['startAfter'] = cursor_ts

        print(f'\n[Pagina {page_num}] fetching (startAfterId={cursor_id or "inicio"})...', flush=True)

        try:
            data = ghl_get('/contacts/', params)
        except Exception as e:
            print(f'  [ERROR API pagina {page_num}]: {e}')
            total_errors += 1
            break

        contacts_raw = data.get('contacts') or []
        meta         = data.get('meta') or {}

        if not contacts_raw:
            print('  [fin] sin contactos en esta pagina')
            break

        total_fetched += len(contacts_raw)
        print(f'  {len(contacts_raw)} contactos obtenidos (total: {total_fetched})', flush=True)

        # Mapear
        mapped = []
        for c in contacts_raw:
            try:
                row = map_contact(c)
                if row['contact_id']:
                    mapped.append(row)
            except Exception as e:
                print(f'  [WARN] error mapeando contact {c.get("id","?")}: {e}')
                total_errors += 1

        # Generar SQL
        sql = build_upsert_sql(mapped)

        if dry_run:
            print(f'  [dry-run] SQL generado ({len(sql)} bytes). Primeros 500 chars:')
            print('  ' + sql[:500].replace('\n', '\n  '))
        else:
            out, err = exec_sql_on_vps(ssh, sql, label=f'pagina-{page_num}')
            has_error = 'ERROR' in out.upper() or 'ERROR' in err.upper()
            if has_error:
                print(f'  [ERROR SQL pagina {page_num}]:')
                print('  ' + out[:600])
                if err: print('  stderr: ' + err[:300])
                total_errors += 1
            else:
                print(f'  [OK] batch ejecutado', flush=True)

        total_processed += len(mapped)

        # ── Avanzar cursor ────────────────────────────────────────────────────
        # GHL expone los cursores directamente en meta (no hay que parsear el URL)
        new_cursor_id = meta.get('startAfterId')
        new_cursor_ts = meta.get('startAfter')

        # Condición de fin: última página o cursores sin avance
        if len(contacts_raw) < GHL_PAGE_SIZE:
            print('  [fin] ultima pagina (menos de 100 contactos)')
            break

        if not new_cursor_id:
            print('  [fin] sin cursor en meta.startAfterId')
            break

        if new_cursor_id == cursor_id:
            # Cursor no avanzó — loop detectado, salir
            print(f'  [fin] cursor no avanzo ({new_cursor_id}), deteniendo')
            break

        cursor_id = new_cursor_id
        cursor_ts = new_cursor_ts

        if limit and total_processed >= limit:
            print(f'\n[--limit {limit}] alcanzado, deteniendo.')
            break

        time.sleep(SLEEP_BETWEEN_PAGES)

    # ── Resumen ───────────────────────────────────────────────────────────────
    print('\n' + '=' * 60)
    print(f'  SYNC COMPLETADO')
    print(f'  Paginas:            {page_num}')
    print(f'  Contactos fetched:  {total_fetched}')
    print(f'  Contactos procesados: {total_processed}')
    print(f'  Errores:            {total_errors}')
    print('=' * 60)

    if not dry_run and ssh:
        # Count final
        out, _ = run_cmd(
            ssh,
            f'docker exec {PG_CONTAINER} psql -U {PG_USER} -d {PG_DB} '
            f'-P pager=off -c "SELECT COUNT(*) AS total_current FROM dim_contacts WHERE is_current=TRUE;"',
            timeout=30
        )
        print('\n[DB] Conteo final dim_contacts WHERE is_current=TRUE:')
        print(out)

        # Refresh materialized view
        # Intentamos CONCURRENTLY primero; si falla (no hay unique index sin WHERE),
        # hacemos REFRESH normal (bloquea lecturas brevemente pero es seguro).
        print('\n[DB] Refreshing mv_unified_attribution (CONCURRENTLY)...')
        out2, err2 = run_cmd(
            ssh,
            f'docker exec {PG_CONTAINER} psql -U {PG_USER} -d {PG_DB} '
            f'-P pager=off -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_unified_attribution;" 2>&1',
            timeout=300
        )
        combined = (out2 + err2).upper()
        if 'ERROR' in combined and 'CONCURRENTLY' in combined:
            print('[INFO] CONCURRENTLY no disponible, usando REFRESH normal...')
            out3, err3 = run_cmd(
                ssh,
                f'docker exec {PG_CONTAINER} psql -U {PG_USER} -d {PG_DB} '
                f'-P pager=off -c "REFRESH MATERIALIZED VIEW mv_unified_attribution;" 2>&1',
                timeout=300
            )
            print(out3)
            if err3 and 'ERROR' in err3.upper():
                print('[WARN mv_refresh normal] ' + err3[:400])
            else:
                print('[OK] mv_unified_attribution refrescada (modo normal)')
        else:
            print(out2)
            if err2 and 'ERROR' in err2.upper():
                print('[WARN mv_refresh] ' + err2[:400])
            else:
                print('[OK] mv_unified_attribution refrescada (CONCURRENTLY)')

        ssh.close()


if __name__ == '__main__':
    main()
