import paramiko

host = "72.60.67.214"
user = "root"
password = "Sixteam2026-"

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=password, timeout=15)

def run(cmd, timeout=20):
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    stdout.channel.settimeout(timeout)
    try:
        out = stdout.read().decode("utf-8", errors="replace")
        err = stderr.read().decode("utf-8", errors="replace")
        return out + err
    except Exception as e:
        return f"[TIMEOUT/ERROR: {e}]"

# The superuser is ghl_user, not postgres
print("=== METABASE DATABASE 2 DETAILS (via ghl_user) ===")
print(run("""docker exec postgres_dashboard-postgres-1 psql -U ghl_user -d metabase_app -c \
"SELECT id, name, engine, details FROM metabase_database;" 2>&1"""))

print("\n=== ALL USERS IN postgres_dashboard-postgres-1 ===")
print(run("docker exec postgres_dashboard-postgres-1 psql -U ghl_user -c \"SELECT usename FROM pg_user;\" 2>&1"))

print("\n=== DATABASES IN postgres_dashboard-postgres-1 ===")
print(run("docker exec postgres_dashboard-postgres-1 psql -U ghl_user -l 2>&1"))

# Check metabase_user password hash
print("\n=== metabase_user HASH ===")
print(run("docker exec postgres_dashboard-postgres-1 psql -U ghl_user -c \"SELECT usename, passwd FROM pg_shadow WHERE usename='metabase_user';\" 2>&1"))

# Check if metabase container can reach postgres container on network
print("\n=== NETWORK: metabase -> postgres (port 5432) ===")
print(run("docker exec postgres_dashboard-metabase-1 sh -c 'nc -zv postgres 5432 2>&1 || echo cannot reach'"))

# Check what network they share
print("\n=== DOCKER NETWORKS ===")
print(run("docker network ls"))
print(run("docker inspect postgres_dashboard-metabase-1 --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}\\n{{end}}'"))
print(run("docker inspect postgres_dashboard-postgres-1 --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}\\n{{end}}'"))

client.close()
print("\n=== DONE ===")
