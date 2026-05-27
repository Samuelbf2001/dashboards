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
        print(safe[:3000] or '(sin output)')
    finally:
        sftp.close()

# Buscar quien levanta n8n-queue-mode
run_safe('systemctl list-units --type=service --state=running | grep -i n8n', 'systemd services n8n')
run_safe('find /etc/systemd /lib/systemd /usr/lib/systemd -name "*n8n*" 2>/dev/null', 'archivos systemd n8n')
run_safe('crontab -l 2>/dev/null; cat /etc/cron* /var/spool/cron/crontabs/* 2>/dev/null | grep -i n8n', 'cron jobs n8n')
run_safe('ls -la /root/n8n-queue-mode/', 'contenido directorio')
run_safe('cat /root/n8n-queue-mode/docker-compose.yml.disabled 2>/dev/null | head -5 || echo "archivo disabled existe"', 'compose disabled')

# Ver si EasyPanel tiene config de este proyecto
run_safe('find /etc/easypanel -name "*.yml" -o -name "*.yaml" 2>/dev/null | xargs grep -l "n8n-queue-mode" 2>/dev/null || echo "no encontrado en easypanel"', 'easypanel config n8n-queue')
run_safe('ls /etc/easypanel/projects/', 'proyectos easypanel')
run_safe('find /etc/easypanel/projects -type f | head -30', 'archivos proyectos easypanel')

# Ver logs de quien inicio los contenedores
run_safe('journalctl -u docker --since "10 minutes ago" --no-pager | grep -i "n8n-queue" | tail -20', 'docker journal n8n-queue')

# Ver si hay algun script o servicio en /root
run_safe('ls -la /root/ | head -20', 'archivos en /root')
run_safe('cat /root/*.sh 2>/dev/null | head -30 || echo "sin .sh en /root"', 'scripts en root')

client.close()
