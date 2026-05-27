import paramiko
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('72.60.67.214', username='root', password='Sixteam2026-', timeout=30)

def run_sql(label, sql):
    print(label)
    print('-' * 60)
    sftp = ssh.open_sftp()
    with sftp.file('/tmp/q.sql', 'w') as f:
        f.write(sql + '\n')
    sftp.close()
    cmd = "docker exec -i postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics < /tmp/q.sql"
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=30)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    print(out)
    if err.strip():
        print('STDERR:', err.strip())
    print()

# Fix queries based on actual schema
queries = [
    ('=== COUNT by stage_name (correct column) ===',
     "SELECT stage_name, status, COUNT(*) as cnt "
     "FROM dim_opportunities WHERE is_current=true "
     "GROUP BY stage_name, status ORDER BY cnt DESC;"),

    ('=== SAMPLE dim_contacts (no full_name, check actual cols) ===',
     "SELECT contact_id, first_name, last_name, utm_source_first, utm_medium_first, "
     "utm_campaign_first, ad_name_first, adset_name_first, ghl_created_at "
     "FROM dim_contacts WHERE ad_name_first IS NOT NULL AND is_current=true LIMIT 5;"),

    ('=== dim_opportunities row count and date range (ghl_created_at) ===',
     "SELECT COUNT(*) as total, MIN(ghl_created_at) as oldest, MAX(ghl_created_at) as newest "
     "FROM dim_opportunities WHERE is_current=true;"),

    ('=== dim_contacts row count and date range ===',
     "SELECT COUNT(*) as total, MIN(ghl_created_at) as oldest, MAX(ghl_created_at) as newest "
     "FROM dim_contacts WHERE is_current=true;"),

    ('=== adset_name_first in dim_contacts - check if col exists ===',
     "SELECT column_name FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name='dim_contacts' "
     "AND column_name ILIKE '%adset%';"),

    ('=== dim_opportunities - pipeline_id and count ===',
     "SELECT pipeline_id, pipeline_name, COUNT(*) as total "
     "FROM dim_opportunities WHERE is_current=true "
     "GROUP BY pipeline_id, pipeline_name;"),

    ('=== dim_pipelines schema ===',
     "SELECT column_name, data_type FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name='dim_pipelines' "
     "ORDER BY ordinal_position;"),

    ('=== dim_pipelines sample ===',
     "SELECT * FROM dim_pipelines LIMIT 10;"),

    ('=== fact_opp_stage_history - count and sample ===',
     "SELECT COUNT(*) as total_transitions, "
     "MIN(changed_at) as oldest, MAX(changed_at) as newest "
     "FROM fact_opp_stage_history;"),

    ('=== fact_opp_stage_history - avg time per stage ===',
     "SELECT to_stage_name, COUNT(*) as entries, "
     "ROUND(AVG(time_in_prev_stage_sec)/3600.0, 1) as avg_hours_in_prev_stage "
     "FROM fact_opp_stage_history "
     "WHERE time_in_prev_stage_sec IS NOT NULL "
     "GROUP BY to_stage_name ORDER BY avg_hours_in_prev_stage DESC;"),

    ('=== ghl_appointments count and status breakdown ===',
     "SELECT status, COUNT(*) as cnt FROM ghl_appointments GROUP BY status ORDER BY cnt DESC;"),

    ('=== ghl_appointments date range ===',
     "SELECT COUNT(*), MIN(start_time) as earliest, MAX(start_time) as latest "
     "FROM ghl_appointments;"),

    ('=== fact_ctwa_clicks count and conversion rate ===',
     "SELECT COUNT(*) as total_clicks, "
     "COUNT(converted_to_opp_id) as converted, "
     "ROUND(COUNT(converted_to_opp_id)*100.0/NULLIF(COUNT(*),0),1) as conversion_pct "
     "FROM fact_ctwa_clicks;"),

    ('=== dim_ads schema ===',
     "SELECT column_name, data_type FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name='dim_ads' "
     "ORDER BY ordinal_position;"),

    ('=== dim_ads sample ===',
     "SELECT * FROM dim_ads LIMIT 5;"),

    ('=== dim_conversations schema ===',
     "SELECT column_name, data_type FROM information_schema.columns "
     "WHERE table_schema='public' AND table_name='dim_conversations' "
     "ORDER BY ordinal_position;"),
]

for label, sql in queries:
    run_sql(label, sql)

ssh.close()
print("DONE")
