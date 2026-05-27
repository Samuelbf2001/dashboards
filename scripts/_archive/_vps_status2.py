import paramiko

host = '72.60.67.214'
user = 'root'
pwd  = 'Sixteam2026-'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, username=user, password=pwd, timeout=20)

def run_safe(cmd, label='', timeout=20):
    print(f'\n--- {label or cmd[:80]} ---')
    _, stdout, stderr = client.exec_command(f'{{ {cmd}; }} > /tmp/out.txt 2>&1', timeout=timeout)
    stdout.read(); stderr.read()
    sftp = client.open_sftp()
    try:
        with sftp.file('/tmp/out.txt', 'rb') as f:
            raw = f.read()
        safe = raw.decode('utf-8', errors='replace').encode('ascii', errors='replace').decode('ascii')
        print(safe[:4000] or '(sin output)')
    finally:
        sftp.close()

run_safe('echo "CPUs: $(nproc)" && uptime', 'CARGA')
run_safe('free -h', 'RAM')
run_safe('ps aux --sort=-%cpu | head -15', 'TOP CPU')
run_safe('ps aux --sort=-%mem | head -10', 'TOP MEM')
run_safe('vmstat 1 3', 'VMSTAT (steal%)')
run_safe('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"', 'CONTENEDORES')

client.close()
