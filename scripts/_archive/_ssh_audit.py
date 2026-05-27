import paramiko

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=15)

commands = [
    ('=== CPU / Load Average ===', 'uptime'),
    ('=== RAM ===', 'free -h'),
    ('=== Disco ===', 'df -h /'),
    ('=== Top 12 procesos por CPU ===', 'ps aux --sort=-%cpu | head -13'),
    ('=== Top 12 procesos por MEM ===', 'ps aux --sort=-%mem | head -13'),
    ('=== Docker containers ===', 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "docker no disponible"'),
    ('=== Conexiones establecidas ===', 'ss -s'),
    ('=== IO espera / interrupciones ===', 'vmstat 1 3'),
]

for title, cmd in commands:
    print(title)
    _, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    print(out or err)
    print()

client.close()
