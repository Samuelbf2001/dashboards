"""
Step 1: Find WF-13 and WF-14 IDs in n8n DB
Step 2: Deactivate all 5 polling workflows
Step 3: Verify
"""
import paramiko
import time

HOST = "72.60.67.214"
USER = "root"
PASSWORD = "Sixteam2026-"
CONTAINER = "postgres_n8n-db.1.sxqsblblyp6shqfsjdb0tqn5e"
DB_PASS = "3002408743"
DB_NAME = "postgres"

KNOWN_IDS = {
    "WF-07": "mo51tGfn795DOK22",
    "WF-08": "q63sie4V7CcgTRb0",
    "WF-09": "l70uw4OQcWMwP50a",
}

def run(client, cmd, desc=""):
    if desc:
        print(f"\n>>> {desc}")
    print(f"$ {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode()
    err = stderr.read().decode()
    if out.strip():
        print(out.strip())
    if err.strip():
        print("STDERR:", err.strip())
    return out, err

def pg(client, sql, desc=""):
    cmd = f'docker exec {CONTAINER} psql -U postgres -d {DB_NAME} -c "{sql}"'
    return run(client, cmd, desc)

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=15)
print("Connected to VPS.")

# Step 1: Find WF-13 and WF-14
out, _ = pg(
    client,
    "SELECT id, name, active FROM workflow_entity WHERE name LIKE '%Poll%' OR name LIKE '%WF-13%' OR name LIKE '%WF-14%';",
    "Search for WF-13 and WF-14 IDs"
)

# Step 2: Build full ID list with known IDs + any found from the query
all_ids = list(KNOWN_IDS.values())

# Parse the query result to extract additional IDs not already known
for line in out.splitlines():
    line = line.strip()
    if not line or line.startswith("id") or line.startswith("--") or line.startswith("("):
        continue
    parts = [p.strip() for p in line.split("|")]
    if len(parts) >= 1:
        wf_id = parts[0].strip()
        if wf_id and wf_id not in all_ids and len(wf_id) > 4:
            print(f"Found additional ID from query: {wf_id} -> {parts[1] if len(parts) > 1 else '?'}")
            all_ids.append(wf_id)

print(f"\nFull ID list to deactivate: {all_ids}")

# Step 3: Deactivate all
id_list = ", ".join(f"'{i}'" for i in all_ids)
pg(
    client,
    f"UPDATE workflow_entity SET active = false WHERE id IN ({id_list});",
    "Deactivate all polling workflows"
)

# Step 4: Verify
pg(
    client,
    f"SELECT id, name, active FROM workflow_entity WHERE id IN ({id_list});",
    "Verify active=false"
)

client.close()
print("\nDone.")
