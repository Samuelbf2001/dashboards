import paramiko
import sys
import time

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('72.60.67.214', username='root', password='Sixteam2026-', timeout=30)

PSQL = 'docker exec -i postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics'

def run_sql(label, sql):
    print(label)
    print('-' * 60)
    # Write sql to a temp file on remote, then pipe it
    sftp = ssh.open_sftp()
    with sftp.file('/tmp/q.sql', 'w') as f:
        f.write(sql + '\n')
    sftp.close()
    cmd = f"docker exec -i postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics < /tmp/q.sql"
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=30)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    print(out)
    if err.strip():
        print('STDERR:', err.strip())
    print()

queries = [
    ('=== ALL TABLES IN PUBLIC SCHEMA ===',
     "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;"),

    ('=== SCHEMA: dim_contacts ===',
     "SELECT column_name, data_type, character_maximum_length, is_nullable "
     "FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name='dim_contacts' "
     "ORDER BY ordinal_position;"),

    ('=== SCHEMA: dim_opportunities ===',
     "SELECT column_name, data_type, character_maximum_length, is_nullable "
     "FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name='dim_opportunities' "
     "ORDER BY ordinal_position;"),

    ('=== SCHEMA: fact_* tables ===',
     "SELECT table_name, column_name, data_type "
     "FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name LIKE 'fact_%' "
     "ORDER BY table_name, ordinal_position;"),

    ('=== SCHEMA: appointments/calendar/cita tables ===',
     "SELECT table_name, column_name, data_type "
     "FROM information_schema.columns "
     "WHERE table_schema='public' "
     "AND (table_name ILIKE '%appoint%' OR table_name ILIKE '%cita%' OR table_name ILIKE '%calendar%') "
     "ORDER BY table_name, ordinal_position;"),

    ('=== SAMPLE 3 rows dim_opportunities (expanded) ===',
     r"\x" + "\nSELECT * FROM dim_opportunities LIMIT 3;"),

    ('=== COUNT by pipeline_stage_name ===',
     "SELECT pipeline_stage_name, COUNT(*) as cnt "
     "FROM dim_opportunities "
     "GROUP BY pipeline_stage_name "
     "ORDER BY cnt DESC;"),

    ('=== COLUMNS SHARED between dim_contacts and dim_opportunities ===',
     "SELECT c.column_name as contacts_col, o.column_name as opps_col "
     "FROM information_schema.columns c "
     "JOIN information_schema.columns o "
     "  ON lower(c.column_name)=lower(o.column_name) "
     "WHERE c.table_name='dim_contacts' AND c.table_schema='public' "
     "  AND o.table_name='dim_opportunities' AND o.table_schema='public';"),

    ('=== SAMPLE dim_contacts WITH attribution ===',
     "SELECT contact_id, full_name, utm_source_first, utm_medium_first, "
     "utm_campaign_first, ad_name_first, adset_name_first, created_at "
     "FROM dim_contacts WHERE ad_name_first IS NOT NULL LIMIT 5;"),

    ('=== COUNT contacts with attribution data ===',
     "SELECT "
     "COUNT(*) FILTER (WHERE ad_name_first IS NOT NULL) as has_ad_name, "
     "COUNT(*) FILTER (WHERE utm_source_first IS NOT NULL) as has_utm_source, "
     "COUNT(*) as total_contacts "
     "FROM dim_contacts;"),

    ('=== dim_opportunities columns related to contact ===',
     "SELECT column_name, data_type "
     "FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name='dim_opportunities' "
     "AND column_name ILIKE '%contact%' "
     "ORDER BY ordinal_position;"),

    ('=== PIPELINE NAMES in dim_opportunities ===',
     "SELECT DISTINCT pipeline_name, pipeline_id FROM dim_opportunities ORDER BY pipeline_name;"),

    ('=== dim_opportunities row count and date range ===',
     "SELECT COUNT(*) as total, MIN(created_at) as oldest, MAX(created_at) as newest FROM dim_opportunities;"),

    ('=== dim_contacts row count and date range ===',
     "SELECT COUNT(*) as total, MIN(created_at) as oldest, MAX(created_at) as newest FROM dim_contacts;"),
]

for label, sql in queries:
    run_sql(label, sql)

ssh.close()
print("DONE")
