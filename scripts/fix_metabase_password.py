import paramiko, time

host = "72.60.67.214"
user = "root"
password = "Sixteam2026-"

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=password, timeout=15)

def run(cmd, timeout=30):
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    stdout.channel.settimeout(timeout)
    try:
        out = stdout.read().decode("utf-8", errors="replace")
        err = stderr.read().decode("utf-8", errors="replace")
        return out + err
    except Exception as e:
        return f"[TIMEOUT/ERROR: {e}]"

print("=== Waiting 10 minutes... ===")
time.sleep(600)

print("\n=== STATUS ===")
print(run('docker ps --format "table {{.Names}}\t{{.Status}}" | grep metabase'))

print("\n=== HEALTH ENDPOINT ===")
print(run("docker exec postgres_dashboard-metabase-1 curl -s http://localhost:3000/api/health 2>&1 || echo 'NOT READY'"))

print("\n=== RECENT LOGS ===")
logs = run("docker logs --since 3m postgres_dashboard-metabase-1 2>&1", timeout=25)
safe = logs.encode("ascii", errors="replace").decode("ascii")
print(safe[-3000:])

client.close()
print("\n=== DONE ===")
