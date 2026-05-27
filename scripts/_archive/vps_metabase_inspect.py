"""TAREA 2 — Diagnostico read-only de Metabase al 87% CPU.

Recolecta logs de Metabase y 3 snapshots de pg_stat_activity (cada 5s)
desde el postgres del dashboard, para ver que queries esta corriendo.
"""
import paramiko
import sys

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
echo '===[1] METABASE LOGS --tail 100 ==='
docker logs postgres_dashboard-metabase-1 --tail 100 2>&1

echo
echo '===[2] METABASE STATE ==='
docker inspect postgres_dashboard-metabase-1 --format 'Started={{.State.StartedAt}} Restarts={{.RestartCount}} OOM={{.State.OOMKilled}} Status={{.State.Status}}'

echo
echo '===[3] DOCKER STATS METABASE + POSTGRES (snapshot) ==='
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -E "metabase|postgres_dashboard-postgres"

echo
echo '===[4] PG_STAT_ACTIVITY snapshot #1 ==='
docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics -c "SELECT pid, usename, application_name, state, wait_event_type, wait_event, EXTRACT(EPOCH FROM (now() - query_start))::int AS sec_running, substring(query, 1, 250) AS query FROM pg_stat_activity WHERE state != 'idle' AND query NOT ILIKE '%pg_stat_activity%' ORDER BY query_start LIMIT 20;"

echo
echo '===[5] SLEEP 5s + snapshot #2 ==='
sleep 5
docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics -c "SELECT pid, usename, application_name, state, wait_event_type, wait_event, EXTRACT(EPOCH FROM (now() - query_start))::int AS sec_running, substring(query, 1, 250) AS query FROM pg_stat_activity WHERE state != 'idle' AND query NOT ILIKE '%pg_stat_activity%' ORDER BY query_start LIMIT 20;"

echo
echo '===[6] SLEEP 5s + snapshot #3 ==='
sleep 5
docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics -c "SELECT pid, usename, application_name, state, wait_event_type, wait_event, EXTRACT(EPOCH FROM (now() - query_start))::int AS sec_running, substring(query, 1, 250) AS query FROM pg_stat_activity WHERE state != 'idle' AND query NOT ILIKE '%pg_stat_activity%' ORDER BY query_start LIMIT 20;"

echo
echo '===[7] CONTEO POR APP + ESTADO ==='
docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics -c "SELECT application_name, state, count(*) FROM pg_stat_activity GROUP BY 1,2 ORDER BY 3 DESC;"

echo
echo '===[8] LOCKS ACTIVOS ==='
docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d ghl_analytics -c "SELECT pid, locktype, relation::regclass, mode, granted FROM pg_locks WHERE NOT granted LIMIT 20;"

echo
echo '===[9] PROCESOS DENTRO DEL CONTENEDOR METABASE (top CPU) ==='
docker exec postgres_dashboard-metabase-1 sh -c "ps -eo pid,pcpu,pmem,comm --sort=-pcpu 2>/dev/null | head -n 10" 2>&1
"""


def main() -> int:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(HOST, username=USER, password=PASS, timeout=30)
    except Exception as e:
        print(f"[ERROR] conexion SSH fallo: {e}", file=sys.stderr)
        return 1
    try:
        _, out, err = client.exec_command(DIAG, timeout=180)
        print(out.read().decode(errors="replace"))
        e = err.read().decode(errors="replace")
        if e.strip():
            print("---[STDERR]---", file=sys.stderr)
            print(e, file=sys.stderr)
    finally:
        client.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
