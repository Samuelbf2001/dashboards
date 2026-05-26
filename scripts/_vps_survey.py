import paramiko, sys

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=15)

def run(cmd, timeout=30):
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    return (out or err).strip()

sections = [
    ('LOAD / CPU', 'uptime && nproc'),
    ('RAM', 'free -h'),
    ('DISCO', 'df -h'),
    ('PROCESOS TOP CPU', 'ps aux --sort=-%cpu | head -20'),
    ('PROCESOS TOP MEM', 'ps aux --sort=-%mem | head -20'),
    ('DOCKER STATS (snapshot)', 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"'),
    ('DOCKER CONTAINERS ALL', 'docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"'),
    ('DOCKER COMPOSE PROJECTS', 'docker compose ls 2>/dev/null || docker-compose ls 2>/dev/null || echo "no compose ls"'),
    ('DOCKER VOLUMES', 'docker volume ls'),
    ('DOCKER NETWORKS', 'docker network ls'),
    ('EASYPANEL PROJECTS', 'ls /etc/easypanel/ 2>/dev/null && cat /etc/easypanel/projects.json 2>/dev/null | python3 -m json.tool 2>/dev/null | head -80 || echo "no projects.json"'),
    ('EASYPANEL DIR', 'ls -la /etc/easypanel/ 2>/dev/null'),
    ('JOURNALCTL DOCKERD', 'journalctl -u docker -n 30 --no-pager 2>/dev/null'),
    ('DOCKER EVENTS RECENT', 'docker events --since 1h --until now --format "{{.Time}} {{.Type}} {{.Action}} {{.Actor.Attributes}}" 2>/dev/null | tail -30 || echo "no events"'),
    ('UNHEALTHY PORTAL LOGS', 'docker logs --tail 30 code-portal-1 2>&1 || echo "no container"'),
    ('UNHEALTHY PORTAL2 LOGS', 'docker logs --tail 30 postgres_dashboard-portal-1 2>&1 || echo "no container"'),
    ('N8N RECENT LOGS', 'docker logs --tail 20 n8n-queue-mode-n8n-1 2>&1 || echo "no container"'),
    ('DOCKERD CHILD PROCS', 'pstree -p 1056 2>/dev/null | head -20 || echo "pstree no disponible"'),
    ('VMSTAT', 'vmstat 1 5'),
    ('IOSTAT', 'iostat -x 1 3 2>/dev/null || echo "iostat no disponible"'),
    ('OPEN FILES TOP', 'lsof 2>/dev/null | awk "{print $1}" | sort | uniq -c | sort -rn | head -20 || echo "lsof no disponible"'),
    ('GREP STUCK PID', 'ls -la /proc/805427/ 2>/dev/null && cat /proc/805427/status 2>/dev/null || echo "proceso ya no existe"'),
    ('SWAP CONFIG', 'swapon --show 2>/dev/null || echo "sin swap"'),
    ('KERNEL VERSION', 'uname -a'),
    ('UPTIME / USERS', 'who && last | head -10'),
]

for title, cmd in sections:
    print(f'\n{"="*60}')
    print(f'  {title}')
    print(f'{"="*60}')
    try:
        result = run(cmd, timeout=20)
        print(result)
    except Exception as e:
        print(f'[ERROR] {e}')

client.close()
print('\n\n=== SURVEY COMPLETO ===')
