import paramiko, sys
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

queries = [
    # The stage_name and pipeline_name are blank — are they being populated via a join with dim_pipelines?
    ('=== opp stage join with dim_pipelines ===',
     """SELECT o.opportunity_id, o.pipeline_stage_id,
        p.stage_name as pipeline_stage_name, p.stage_order,
        p.is_won_stage, p.is_lost_stage,
        o.status, o.monetary_value
     FROM dim_opportunities o
     LEFT JOIN dim_pipelines p ON o.pipeline_stage_id = p.stage_id
     WHERE o.is_current=true
     LIMIT 10;"""),

    ('=== Count opps by stage via join ===',
     """SELECT p.stage_name, p.stage_order, o.status, COUNT(*) as cnt,
        SUM(o.monetary_value) as total_value
     FROM dim_opportunities o
     LEFT JOIN dim_pipelines p ON o.pipeline_stage_id = p.stage_id
     WHERE o.is_current=true
     GROUP BY p.stage_name, p.stage_order, o.status
     ORDER BY p.stage_order NULLS LAST, o.status;"""),

    # Check mv_unified_attribution schema
    ('=== SCHEMA: mv_unified_attribution ===',
     """SELECT column_name, data_type FROM information_schema.columns
     WHERE table_schema='public' AND table_name='mv_unified_attribution'
     ORDER BY ordinal_position;"""),

    ('=== mv_unified_attribution sample 3 rows ===',
     r"\x" + "\nSELECT * FROM mv_unified_attribution LIMIT 3;"),

    ('=== mv_unified_attribution row count ===',
     "SELECT COUNT(*) FROM mv_unified_attribution;"),

    # dim_contacts attribution distribution
    ('=== Attribution source breakdown in dim_contacts ===',
     """SELECT utm_source_first, COUNT(*) as cnt
     FROM dim_contacts WHERE is_current=true
     GROUP BY utm_source_first ORDER BY cnt DESC LIMIT 20;"""),

    ('=== Ad names in dim_contacts ===',
     """SELECT ad_name_first, COUNT(*) as cnt
     FROM dim_contacts WHERE is_current=true AND ad_name_first IS NOT NULL
     GROUP BY ad_name_first ORDER BY cnt DESC LIMIT 20;"""),

    # dim_conversations stats
    ('=== dim_conversations count, channel_type breakdown ===',
     """SELECT channel_type, COUNT(*) as cnt,
        COUNT(ad_name) as has_ad_name,
        AVG(first_reply_seconds)/60.0 as avg_first_reply_min
     FROM dim_conversations WHERE is_current=true
     GROUP BY channel_type ORDER BY cnt DESC;"""),

    # Check if opp has monetary_value populated
    ('=== monetary_value distribution in opp ===',
     """SELECT
        COUNT(*) FILTER (WHERE monetary_value > 0) as has_value,
        COUNT(*) FILTER (WHERE monetary_value = 0 OR monetary_value IS NULL) as no_value,
        MAX(monetary_value) as max_val,
        SUM(monetary_value) as total
     FROM dim_opportunities WHERE is_current=true;"""),

    # assigned_to_name blank — check
    ('=== assigned_to_name in opps ===',
     """SELECT assigned_to_name, COUNT(*) as cnt
     FROM dim_opportunities WHERE is_current=true
     GROUP BY assigned_to_name ORDER BY cnt DESC LIMIT 10;"""),

    # ghl_sync_state
    ('=== ghl_sync_state ===',
     "SELECT * FROM ghl_sync_state;"),

    # fact_messages stats
    ('=== fact_messages count and channel breakdown ===',
     """SELECT message_type, direction, COUNT(*) as cnt
     FROM fact_messages
     GROUP BY message_type, direction ORDER BY cnt DESC LIMIT 20;"""),
]

for label, sql in queries:
    run_sql(label, sql)

ssh.close()
print("DONE")
